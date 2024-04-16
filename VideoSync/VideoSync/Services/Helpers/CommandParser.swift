//
//  CommandParser.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import Foundation

final class CommandParser {
    private let message: Message
    
    init(message: Message) {
        self.message = message
    }
    
    func parse(
        startVideo: (Command.StartVideo) -> Void,
        stopVideo: (Command.StopVideo) -> Void,
        initializeRequest: (Command.InitializeRequest) -> Void,
        initializeResponse: (Command.InitializeResponse) -> Void
    ) {
        guard let body = message.body else { return }
        if body.starts(with: Command.startVideo.rawValue) {
            let link = body
                .replacingOccurrences(of: Command.startVideo.rawValue, with: "")
                .trimmingCharacters(in: .whitespaces)
            startVideo(Command.StartVideo(senderID: message.senderID, link: link))
        } else if body.starts(with: Command.stopVideo.rawValue) {
            stopVideo(Command.StopVideo(senderID: message.senderID))
        } else if body.starts(with: Command.initializeRequest.rawValue) {
            initializeRequest(Command.InitializeRequest(senderID: message.senderID))
        } else if body.starts(with: Command.initializeResponse.rawValue) {
            guard let data = decodedData(type: Command.InitializeResponseData.self, data: message.data) else { return }
            initializeResponse(Command.InitializeResponse(senderID: message.senderID, data: data))
        }
    }
}
