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
    @Published var isInitialized: Bool
    
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
    }
    
    deinit {
        cancellable.forEach() { $0.cancel() }
    }
        
    func sendMessage() {
        let message = ChatMessage(body: messageInput)
        send(message: message)
        messageInput = ""
    }
    
    func send(message: ChatMessage) {
        message.senderID = chatManager.currentUserID
        onMessageUpdate(message)
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
            self?.onMessageUpdate(msg)
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
        guard msg.isVisible && !(msg.body ?? "").isEmpty else { return }
        messages.append(msg)
    }
    
    private func onMessageUpdate(_ msg: ChatMessage) {
        do {
            try CommandParser(message: msg).parse(
                startVideo: { cmd in
                    guard isInitialized else { return }
                    appendMessage(msg)
                    videoStreamerID = msg.senderID
                    updateLink(cmd.link)
                    if commandOwner(cmd) {
                        chatManager.send(message: msg)
                    }
                },
                stopVideo: { cmd in
                    guard isInitialized else { return }
                    if videoLink == nil || videoStreamerID == nil {
                        sendError("Video not playing")
                    } else {
                        videoStreamerID = nil
                        updateLink(nil)
                        appendMessage(msg)
                    }
                    if commandOwner(cmd) {
                        chatManager.send(message: msg)
                    }
                },
                initializeRequest: { cmd in
                    guard isInitialized else { return }
                    guard isHost else { return }
                    initializeResponse(receiverID: msg.senderID)
                },
                initializeResponse: { cmd in
                    guard cmd.data.receiverID == chatManager.currentUserID else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.videoStreamerID = cmd.data.videoStreamerID
                        self.updateLink(cmd.data.videoLink)
                        self.isInitialized = true
                    }
                }, onDefault: { msg in
                    guard isInitialized else { return }
                    appendMessage(msg)
                    if msg.senderID == chatManager.currentUserID {
                        chatManager.send(message: msg)
                    }
                }
            )
        } catch {
            return
        }
    }
    
    private func commandOwner(_ cmd: ChatCommand) -> Bool {
        return cmd.senderID == chatManager.currentUserID
    }
    
    private func initializeRequest() {
        let message = ChatMessage(
            type: .system,
            body: Command.initializeRequest.rawValue
        )
        chatManager.send(message: message)
    }
    
    private func initializeResponse(receiverID: String) {
        let data = Command.InitializeResponseData(
            receiverID: receiverID,
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
    
    private func sendError(_ msg: String?) {
        let message = ChatMessage(
            type: .error,
            body: msg,
            senderID: chatManager.currentUserID
        )
        appendMessage(message)
    }
}
