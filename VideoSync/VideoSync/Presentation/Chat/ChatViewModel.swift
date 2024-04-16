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
    @Published var isInitialized: Bool = false
    
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
        self.isInitialized = isHost
        configure()
        print("Init")
    }
    
    deinit {
        cancellable.forEach() { $0.cancel() }
        print("Deinit")
    }
        
    func sendMessage() {
        let message = ChatMessage(body: messageInput)
        send(message: message)
        messageInput = ""
    }
    
    func send(message: ChatMessage) {
        message.senderID = chatManager.currentUserID
        appendMessage(message)
        onMessageUpdate(message)
    }
    
    func isOutgoingMessage(_ msg: ChatMessage) -> Bool {
        return chatManager.currentUserID == msg.senderID
    }
    
    func onAppear() {
        sendInitialRequest()
    }
    
    private func configure() {
        let onReceiveMsg = chatManager.onRecieveMessage.sink() { [weak self] msg in
            self?.appendMessage(msg)
            self?.onMessageUpdate(msg)
        }
        cancellable.append(onReceiveMsg)
    }
    
    private func onMessageUpdate(_ msg: ChatMessage) {
        do {
            try CommandParser(message: msg).parse(
                startVideo: { cmd in
                    startVideo(msg, cmd)
                },
                stopVideo: { cmd in
                    stopVideo(msg, cmd)
                },
                initializeRequest: { cmd in
                    initializeRequest(msg, cmd)
                },
                initializeResponse: { cmd in
                    initializeResponse(msg, cmd)
                }, onDefault: { msg in
                    onDefault(msg)
                }
            )
        } catch let error as CommandParserError {
            sendError(error.errorMessage)
        } catch {
            //
        }
    }
    
    private func startVideo(_ msg: ChatMessage, _ cmd: Command.StartVideo) {
        guard isInitialized else { return }
        videoStreamerID = msg.senderID
        updateLink(cmd.link)
        forwardMessageIfNeeded(msg)
    }
    
    private func stopVideo(_ msg: ChatMessage, _ cmd: Command.StopVideo) {
        guard isInitialized else { return }
        if videoLink == nil || videoStreamerID == nil {
            sendError("Video not playing")
        } else {
            videoStreamerID = nil
            updateLink(nil)
            forwardMessageIfNeeded(msg)
        }
    }
    
    private func initializeResponse(_ msg: ChatMessage, _ cmd: Command.InitializeResponse) {
        guard cmd.data.receiverID == chatManager.currentUserID else { return }
        self.isInitialized = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.videoStreamerID = cmd.data.videoStreamerID
            self.updateLink(cmd.data.videoLink)
            self.isInitialized = true
        }
    }
    
    private func initializeRequest(_ msg: ChatMessage, _ cmd: Command.InitializeRequest) {
        guard isInitialized else { return }
        guard isHost else { return }
        let data = Command.InitializeResponseData(
            receiverID: msg.senderID,
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
    
    private func onDefault(_ msg: ChatMessage) {
        guard isInitialized else { return }
        forwardMessageIfNeeded(msg)
    }
    
    private func sendInitialRequest() {
        guard !isHost else { return }
        let message = ChatMessage(
            type: .system,
            body: Command.initializeRequest.rawValue
        )
        chatManager.send(message: message)
    }
    
    private func sendError(_ msg: String?) {
        let message = ChatMessage(
            type: .error,
            body: msg,
            senderID: chatManager.currentUserID
        )
        appendMessage(message)
    }
    
    private func updateLink(_ link: String?) {
        withAnimation {
            self.videoLink = link
            self.isPlayerOpened = !(link ?? "").isEmpty
        }
    }
    
    private func appendMessage(_ msg: ChatMessage) {
        guard isInitialized && msg.isVisible && !(msg.body ?? "").isEmpty else { return }
        messages.append(msg)
    }
    
    private func forwardMessageIfNeeded(_ msg: ChatMessage) {
        if msg.senderID == chatManager.currentUserID {
            chatManager.send(message: msg)
        }
    }
}
