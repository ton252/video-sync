//
//  CommandPerformer.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import Foundation

class CommandPerformer {
    var onVideoStart: ((MessageModel, String) -> ())?
    var onVideoStop: ((MessageModel) -> ())?
    
    init(
        onVideoStart: ((MessageModel, String) -> ())? = nil,
        onVideoStop: ((MessageModel) -> ())? = nil
    ) {
        self.onVideoStart = onVideoStart
        self.onVideoStop = onVideoStop
    }
    
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
        }
    }
}
