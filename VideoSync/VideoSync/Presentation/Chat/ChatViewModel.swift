//
//  ChatViewModel.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import Foundation
import SwiftUI
import Combine


final class ChatViewModel: ObservableObject {
    let isHost: Bool
    let chatManager: ChatManager
    
    @Published var messages: [ChatMessage] = []
    @Published var messageInput: String = ""
    @Published var videoLink: String? = nil
    @Published var videoStreamerID: String? = nil
    @Published var isPlayerOpened: Bool = false
    
    @Published var commands = [
        CommandItem(command: "/start_video"),
        CommandItem(command: "/stop_video"),
    ]
    
    var title: String {
        return isHost ? "Host" : "Peer"
    }
    
    private var cancellable: [Cancellable] = []
    
    init(
        isHost: Bool,
        chatManager: ChatManager
    ) {
        self.isHost = isHost
        self.chatManager = chatManager
        configure()
    }
    
    deinit {
        cancellable.forEach() { $0.cancel() }
    }
        
    func sendMessage() {
        let message = ChatMessage(body: messageInput)
        sendChatMessage(message)
        messageInput = ""
    }
    
    func isOutgoingMessage(_ msg: ChatMessage) -> Bool {
        return chatManager.currentUserID == msg.senderID
    }
    
    func onAppear() {
        guard !isHost else { return }
        initializeRequest()
    }
    
    private func configure() {
        let onReceiveMsg = chatManager.onRecieveMessage.sink() { [weak self] msg in
            self?.recieveMessage(msg)
        }
        cancellable.append(onReceiveMsg)
    }

    private func updateLink(_ link: String?) {
        withAnimation {
            self.videoLink = link
            self.isPlayerOpened = !(link ?? "").isEmpty
        }
    }
    
    private func appendMessage(_ msg: ChatMessage) {
        guard msg.isVisible else { return }
        messages.append(msg)
    }
    
    private func recieveMessage(_ msg: ChatMessage) {
        do {
            try CommandParser(message: msg).parse(
                startVideo: { cmd in
                    self.videoStreamerID = msg.senderID
                    updateLink(cmd.link)
                },
                stopVideo: { cmd in
                    self.videoStreamerID = nil
                    updateLink(nil)
                },
                initializeRequest: { cmd in
                    guard isHost else { return }
                    initializeResponse()
                },
                initializeResponse: { cmd in
                    //
                }, onDefault: { message in
                    //
                }
            )
            messages.append(msg)
        } catch {
            return
        }
    }
    
    private func sendChatMessage(_ msg: ChatMessage) {
        msg.senderID = chatManager.currentUserID
        do {
            try CommandParser(message: msg).parse(
                startVideo: { cmd in
                    self.videoStreamerID = chatManager.currentUserID
                    updateLink(cmd.link)
                    appendMessage(msg)
                    chatManager.send(message: msg)
                },
                stopVideo: { cmd in
                    if videoLink == nil || videoStreamerID == nil {
                        sendError("Video not playing")
                    } else {
                        videoStreamerID = nil
                        updateLink(nil)
                    }
                    appendMessage(msg)
                    chatManager.send(message: msg)
                },
                initializeRequest: { cmd in
                    //
                },
                initializeResponse: { cmd in
                    //
                },
                onDefault: { _ in
                    appendMessage(msg)
                    chatManager.send(message: msg)
                }
            )
        } catch let error as CommandParserError {
            sendError(error.errorMessage)
            return
        } catch {
            return
        }
    }
    
    private func initializeRequest() {
        let message = ChatMessage(
            type: .system,
            body: Command.initializeRequest.rawValue
        )
        chatManager.send(message: message)
    }
    
    private func initializeResponse() {
        let data = Command.InitializeResponseData(
            videoLink: videoLink,
            videoStreamerID: videoStreamerID
        )
        let message = ChatMessage(
            type: .system,
            body: Command.initializeResponse.rawValue,
            data: encodedData(data: data)
        )
        chatManager.send(message: message)
    }
    
    private func stopVideo() {
        self.videoStreamerID = nil
        updateLink(nil)
    }
    
    private func sendError(_ msg: String?) {
        let message = ChatMessage(
            type: .error,
            body: msg,
            senderID: chatManager.currentUserID
        )
        appendMessage(message)
    }
}
