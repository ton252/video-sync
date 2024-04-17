//
//  ChatPackage.swift
//  VideoSync
//
//  Created by ton252 on 17.04.2024.
//

import Foundation

final class ChatPackage: Codable {
    var id: String!
    var type: ChatPackageType
    var message: ChatMessage?
    var command: SystemCommand?
    
    init(
        type: ChatPackageType,
        message: ChatMessage? = nil,
        command: SystemCommand? = nil
    ) {
        self.type = type
        self.message = message
        self.command = command
    }
}

enum SystemCommand: String, Codable {
    case disconnectPeers
}

enum ChatPackageType: String, Codable {
    case userMessage
    case system
}
