//
//  ChatPeerID.swift
//  VideoSync
//
//  Created by ton252 on 12.04.2024.
//

import Foundation
import MultipeerConnectivity

class ChatPeerID: MCPeerID {
    let userId: String
    
    init(userId: String, displayName: String?) {
        self.userId = userId
        super.init(displayName: displayName ?? userId)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
