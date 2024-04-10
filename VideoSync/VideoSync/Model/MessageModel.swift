//
//  MessageModel.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import Foundation
import MultipeerConnectivity

enum MessageType: Codable {
    case message
    case system
}

class MessageModel: Codable {
    var id: String!
    let body: String?
    let type: MessageType
    var data: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id, body, type, data
    }
    
    init(
        body: String?,
        type: MessageType = .message,
        data: [String: Any]? = nil
    ) {
        self.body = body
        self.type = type
        self.data = data
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MessageType.self, forKey: .type)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        
        if let rawData = try container.decodeIfPresent(Data.self, forKey: .data) {
            data = try JSONSerialization.jsonObject(with: rawData, options: []) as? [String: Any]
        } else {
            data = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(body, forKey: .body)
        
        // Convert `data` from [String: Any] to Data, then encode
        if let data = data {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            try container.encode(jsonData, forKey: .data)
        }
    }
}
