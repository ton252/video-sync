//
//  Command.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import Foundation

//class Command: Codable {
//    enum Name: String, Codable {
//        case startVideo = "/start_video"
//        case stopVideo = "/stop_video"
//        case initializeRequest = "/initialize_request"
//        case initializeResponse = "/initialize_response"
//    }
//    
//    var senderID: String? = nil
//    var receiverID: String? = nil
//    
//    init(
//        senderID: String? = nil,
//        receiverID: String? = nil
//    ) {
//        self.senderID = senderID
//        self.receiverID = receiverID
//    }
//}
//
//class StartVideo: Command {
//    var link: String = ""
//}

protocol ChatCommand {
    var senderID: String { get }
}

enum Command: String {
    case startVideo = "/start_video"
    case stopVideo = "/stop_video"
    case initializeRequest = "/initialize_request"
    case initializeResponse = "/initialize_response"
    
    struct StartVideo: Codable, ChatCommand {
        var senderID: String
        var link: String
    }
    
    struct StopVideo: Codable, ChatCommand {
        var senderID: String
    }
    
    struct InitializeRequest: Codable, ChatCommand {
        var senderID: String
    }
    
    struct InitializeResponse: Codable, ChatCommand {
        var senderID: String
        var data: InitializeResponseData
    }
    
    struct InitializeResponseData: Codable {
        let receiverID: String
        let videoLink: String?
        let videoStreamerID: String?
    }
}
