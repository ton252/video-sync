//
//  CommandParser.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import Foundation

struct CommandParserError: Error {
    let command: Command
    let errorMessage: String?
    let message: ChatMessage
}

final class CommandParser {
    private let message: ChatMessage
    
    init(message: ChatMessage) {
        self.message = message
    }
    
    func parse(
        startVideo: (Command.StartVideo) -> Void,
        stopVideo: (Command.StopVideo) -> Void,
        syncVideo: (Command.SyncVideo) -> Void,
        initializeRequest: (Command.InitializeRequest) -> Void,
        initializeResponse: (Command.InitializeResponse) -> Void,
        onDefault: (ChatMessage) -> Void
    ) throws {
        guard let body = message.body else { return }
        if body.starts(with: Command.startVideo.rawValue) {
            let link = body
                .replacingOccurrences(of: Command.startVideo.rawValue, with: "")
                .trimmingCharacters(in: .whitespaces)
            guard !link.isEmpty else {
                throw CommandParserError(command: Command.startVideo, errorMessage: "Missing video link", message: message)
            }
            startVideo(Command.StartVideo(senderID: message.senderID, link: link))
        } else if body.starts(with: Command.stopVideo.rawValue) {
            stopVideo(Command.StopVideo(senderID: message.senderID))
        } else if body.starts(with: Command.syncVideo.rawValue) {
            guard let data = decodedData(type: Command.SyncVideoData.self, data: message.data) else { return }
            syncVideo(Command.SyncVideo(senderID: message.senderID, data: data))
        } else if body.starts(with: Command.initializeRequest.rawValue) {
            initializeRequest(Command.InitializeRequest(senderID: message.senderID))
        } else if body.starts(with: Command.initializeResponse.rawValue) {
            guard let data = decodedData(type: Command.InitializeResponseData.self, data: message.data) else { return }
            initializeResponse(Command.InitializeResponse(senderID: message.senderID, data: data))
        } else {
            onDefault(message)
        }
    }
}
