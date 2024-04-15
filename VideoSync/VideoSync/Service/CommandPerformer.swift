//
//  CommandPerformer.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import Foundation

class CommandPerformer {
    var onVideoStart: ((MessageModel, String) -> ())? = nil
    var onVideoStop: ((MessageModel) -> ())? = nil
    var onInitialRequest: ((MessageModel) -> ())? = nil
    var onInitialResponse: ((MessageModel, InitalRequestData) -> ())? = nil
    
    func perform(message: MessageModel) {
        if message.type == .message {
            guard let body = message.body else { return }
            if body.starts(with: "/start_video") {
                let link = body
                    .replacingOccurrences(of: "/start_video", with: "")
                    .trimmingCharacters(in: .whitespaces)
                onVideoStart?(message, link)
            } else if body.starts(with: "/stop_video") {
                onVideoStop?(message)
            }
        } else if message.type == .system {
            guard let body = message.body else { return }
            if body.starts(with: "/initial_request") {
                onInitialRequest?(message)
            } else if body.starts(with: "/initial_response") {
                guard let data = decodedData(type: InitalRequestData.self, data: message.data) else {
                    return
                }
                onInitialResponse?(message, data)
            }
        }
    }
}
