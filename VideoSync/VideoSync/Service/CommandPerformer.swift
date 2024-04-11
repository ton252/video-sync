//
//  CommandPerformer.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import Foundation

class CommandPerformer {
    var onUpdateVideoLink: ((MessageModel, String) -> ())?
    var onPlay: ((String) -> ())?
    var onPause: ((String) -> ())?
    
    init(
        onUpdateVideoLink: ((MessageModel, String) -> ())? = nil,
        onPlay: ((String) -> ())? = nil,
        onPause: ((String) -> ())? = nil
    ) {
        self.onUpdateVideoLink = onUpdateVideoLink
        self.onPlay = onPlay
        self.onPause = onPause
    }
    
    func perform(message: MessageModel) {
        if message.type == .message {
            guard let body = message.body else { return }
            if body.starts(with: "/start_video") {
                let link = body
                    .replacingOccurrences(of: "/start_video", with: "")
                    .trimmingCharacters(in: .whitespaces)
                onUpdateVideoLink?(message, link)
            }
        }
    }
}
