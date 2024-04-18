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
    
    @Published var player = Player()
    @Published var messages: [ChatMessage] = []
    @Published var messageInput: String = ""
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
    
    private var errorDelay: TimeInterval = 0.3
    private var cancellable: [Cancellable] = []
    
    init(
        isHost: Bool,
        chatManager: ChatManager
    ) {
        print("Init ViewModel")
        self.isHost = isHost
        self.chatManager = chatManager
        self.isInitialized = true
        configure()
    }
    
    deinit {
        print("Deinit ViewModel")
        cancellable.forEach() { $0.cancel() }
    }
        
    func sendMessage() {
        let msg = ChatMessage(body: messageInput)
        send(message: msg)
        messageInput = ""
    }
    
    func send(message msg: ChatMessage) {
        msg.senderID = chatManager.currentUserID
        appendMessage(msg)
        onMessageUpdate(msg)
    }
    
    func isOutgoingMessage(_ msg: ChatMessage) -> Bool {
        return chatManager.currentUserID == msg.senderID
    }
    
    func onAppear() {
        // sendInitialRequest()
    }
    
    private func configure() {
        let onReceiveMsg = chatManager.onRecieveMessage.sink() { [weak self] msg in
            self?.appendMessage(msg)
            self?.onMessageUpdate(msg)
        }
        let onPlayerTime = player.onTimeChange.sink() { [weak self] time in
            self?.sendSyncVideo()
        }
        let onStateChange = player.onStateChange.sink() { [weak self] state in
            self?.sendSyncVideo()
        }
        
        cancellable.append(onReceiveMsg)
        cancellable.append(onPlayerTime)
        cancellable.append(onStateChange)
    }
    
    private func onMessageUpdate(_ msg: ChatMessage) {
        let isMessageOwner = self.isMessageOwner(msg)
        CommandParser(message: msg).parse(
            startVideo: { cmd in
                guard isInitialized else { return }
                startVideo(cmd)
                forwardMessageIfNeeded(msg)
            }, stopVideo: { cmd in
                guard isInitialized else { return }
                stopVideo(cmd)
                forwardMessageIfNeeded(msg)
            }, syncVideo: { cmd in
                guard isInitialized else { return }
                guard !isMessageOwner else { return }
                syncVideo(cmd)
            }, initializeRequest: { cmd in
                //
            }, initializeResponse: { cmd in },
            onDefault: { cmd in
                forwardMessageIfNeeded(msg)
            },
            onError: { error in
                sendError(error.errorMessage)
            }
        )
        
    }
    
    private func startVideo(_ cmd: Command.StartVideo) {
        let extractor = YouTubeExtractor()

        guard let videoID = extractor.extractVideoId(link: cmd.link) else {
            sendError("Invalid link")
            return
        }

        videoStreamerID = cmd.senderID
        updateLink(videoID)
        sendSyncVideo()
    }
    
    private func stopVideo(_ cmd: Command.StopVideo) {
        if player.link == nil || videoStreamerID == nil {
            sendError("Video not playing")
        } else {
            videoStreamerID = nil
            updateLink(nil)
        }
    }
    
    private func syncVideo(_ cmd: Command.SyncVideo) {
        let currentTime = Date().timeIntervalSince1970
        let responseTime = currentTime - cmd.data.sendTime
        let newTime = cmd.data.playerTime + responseTime
        
        let playerState = player.state
        let playerCurrentTime = player.currentTime
        let playerBufferingTime = player.bufferingTime
                
        print("""
            System Current Time: \(currentTime)
            Response Time: \(currentTime)
            State (player): \(playerState)
            Current Time (player): \(playerCurrentTime)
            Buffering Time (player): \(playerBufferingTime)
            Address: \(Unmanaged.passUnretained(self).toOpaque())
            Player Address: \(Unmanaged.passUnretained(self.player).toOpaque())
        
            State (remote): \(cmd.data.state)
            Current Time (remote): \(cmd.data.playerTime)
            Send Time (remote): \(cmd.data.sendTime)
            New Time: \(newTime)
            ------------------------------------------------
        
        """)
        
        if player.link != cmd.data.link {
            updateLink(cmd.data.link)
        }
        
        if cmd.data.state == .paused {
            player.seek(to: newTime)
            player.pause()
            return
        }
        
        if player.state == .buffering {
            player.seek(to: newTime)
            player.pause()
            return
        }
        
        if player.bufferingTime < newTime + 2.0 {
            player.seek(to: newTime)
            player.pause()
            return
        }
        
        if cmd.data.state == .playing {
            player.seek(to: newTime)
            player.play()
        }
    }
    
    
    
//    private func initializeRequest(_ msg: ChatMessage, _ cmd: Command.InitializeRequest) {
//        guard isInitialized else { return }
//        guard isHost else { return }
//        let data = Command.InitializeResponseData(
//            receiverID: msg.senderID,
//            videoLink: player.link,
//            videoStreamerID: videoStreamerID
//        )
//        let message = ChatMessage(
//            type: .system,
//            body: Command.initializeResponse.rawValue,
//            data: encodedData(data: data)
//        )
//        chatManager.send(message: message)
//    }
    
//    private func onMessageUpdate(_ msg: ChatMessage) {
//        do {
////            try CommandParser(message: msg).parse(
////                startVideo: { cmd in
////                    startVideo(msg, cmd)
////                },
////                stopVideo: { cmd in
////                    stopVideo(msg, cmd)
////                },
////                syncVideo: { cmd in
////                    syncVideo(msg, cmd)
////                },
////                initializeRequest: { cmd in
////                    initializeRequest(msg, cmd)
////                },
////                initializeResponse: { cmd in
////                    initializeResponse(msg, cmd)
////                }, onDefault: { msg in
////                    onDefault(msg)
////                }
////            )
//        } catch let error as CommandParserError {
//            sendError(error.errorMessage)
//        } catch {
//            //
//        }
//    }
    
//    private func startVideo(_ msg: ChatMessage, _ cmd: Command.StartVideo) {
//        guard isInitialized else { return }
//        guard cmd.senderID == chatManager.currentUserID  else { return }
//        let extractor = YouTubeExtractor()
//        
//        guard let videoID = extractor.extractVideoId(link: cmd.link) else {
//            sendError("Invalid link")
//            return
//        }
//        
//        videoStreamerID = msg.senderID
//        updateLink(videoID)
//        forwardMessageIfNeeded(msg)
//        sendSyncVideo()
//    }
//    
//    private func stopVideo(_ msg: ChatMessage, _ cmd: Command.StopVideo) {
//        guard isInitialized else { return }
//        if player.link == nil || videoStreamerID == nil {
//            sendError("Video not playing")
//        } else {
//            videoStreamerID = nil
//            updateLink(nil)
//            forwardMessageIfNeeded(msg)
//        }
//    }
//    
//    private func initializeResponse(_ msg: ChatMessage, _ cmd: Command.InitializeResponse) {
//        guard cmd.data.receiverID == chatManager.currentUserID else { return }
//        self.isInitialized = true
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.videoStreamerID = cmd.data.videoStreamerID
//            self.updateLink(cmd.data.videoLink)
//            self.isInitialized = true
//        }
//    }
//    
//    private func initializeRequest(_ msg: ChatMessage, _ cmd: Command.InitializeRequest) {
//        guard isInitialized else { return }
//        guard isHost else { return }
//        let data = Command.InitializeResponseData(
//            receiverID: msg.senderID,
//            videoLink: player.link,
//            videoStreamerID: videoStreamerID
//        )
//        let message = ChatMessage(
//            type: .system,
//            body: Command.initializeResponse.rawValue,
//            data: encodedData(data: data)
//        )
//        chatManager.send(message: message)
//    }
//    
//    private func syncVideo(_ msg: ChatMessage, _ cmd: Command.SyncVideo) {
//        guard isInitialized else { return }
//        guard cmd.senderID != chatManager.currentUserID else { return }
//        print("Received /sync_video: \(cmd.data.link) \(cmd.data.state)  \(cmd.data.playerTime)")
//    }
//    
//    private func onDefault(_ msg: ChatMessage) {
//        guard isInitialized else { return }
//        forwardMessageIfNeeded(msg)
//    }
//    
//    private func sendInitialRequest() {
//        guard !isHost else { return }
//        let message = ChatMessage(
//            type: .system,
//            body: Command.initializeRequest.rawValue
//        )
//        chatManager.send(message: message)
//    }
    
    private func sendSyncVideo() {
        guard chatManager.currentUserID == videoStreamerID else { return }
        guard let link = player.link else { return }
        let data = Command.SyncVideoData(
            link: link,
            state: player.state,
            playerTime: player.currentTime,
            sendTime: Date().timeIntervalSince1970
        )
        let message = ChatMessage(
            type: .system,
            body: Command.syncVideo.rawValue,
            data: encodedData(data: data)
        )
        chatManager.send(message: message)
        print("Sended /sync_video: \(data.link) \(data.state)  \(data.playerTime)")
    }
    
    private func sendError(_ msg: String?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + errorDelay) { [weak self] in
            guard let self = self else { return }
            let message = ChatMessage(
                type: .error,
                body: msg,
                senderID: self.chatManager.currentUserID
            )
            self.appendMessage(message)
        }
    }
    
    private func updateLink(_ link: String?) {
        withAnimation {
            self.player.link = link
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
    
    private func isMessageOwner(_ msg: ChatMessage) -> Bool {
        return msg.senderID == chatManager.currentUserID
    }
}
