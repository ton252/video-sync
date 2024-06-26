//
//  MessageModel.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import Foundation

enum ChatMessageType: String, Codable {
    case message
    case system
    case error
}

final class ChatMessage: Codable {
    var id: String
    var type: ChatMessageType

    var senderID: String!
    var receiverID: String?
    
    var body: String?
    var data: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, senderID, body, type, data
    }
    
    var isVisible: Bool {
        return type == .message || type == .error
    }
    
    init(
        type: ChatMessageType = .message,
        body: String?,
        senderID: String? = nil,
        receiverID: String? = nil,
        data: [String: Any]? = nil
    ) {
        self.body = body
        self.type = type
        self.data = data
        self.id = UUID().uuidString
        self.senderID = senderID
        self.receiverID = receiverID
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        senderID = try container.decode(String.self, forKey: .senderID)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        type = try container.decode(ChatMessageType.self, forKey: .type)
        
        if let rawData = try container.decodeIfPresent(Data.self, forKey: .data) {
            data = try JSONSerialization.jsonObject(with: rawData, options: []) as? [String: Any]
        } else {
            data = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderID, forKey: .senderID)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(body, forKey: .body)
        
        // Convert `data` from [String: Any] to Data, then encode
        if let data = data {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            try container.encode(jsonData, forKey: .data)
        }
    }
}
