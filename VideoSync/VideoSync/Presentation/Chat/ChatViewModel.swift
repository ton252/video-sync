//
//  ChatViewModel.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import Foundation
import Combine


final class ChatViewModel: ObservableObject {
    let isHost: Bool
    let chatManager: ChatManager
    
    init(
        isHost: Bool,
        chatManager: ChatManager
    ) {
        self.isHost = isHost
        self.chatManager = chatManager
    }
}
