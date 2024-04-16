//
//  ChatManager.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import Combine
import Foundation
import MultipeerConnectivity

final class ChatManager: NSObject, ObservableObject {
    static let serviceType = "p2p-chat"
    
    let peerID: MCPeerID
    var currentUserID: String { return UIDevice.current.userID }
    
    private(set) var session: MCSession?
    
    let onUpdateMessage = PassthroughSubject<ChatMessage, Never>()
    let onSendMessage = PassthroughSubject<ChatMessage, Never>()
    let onRecieveMessage = PassthroughSubject<ChatMessage, Never>()
    let onRemoteDisconnect = PassthroughSubject<Void, Never>()
    
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let disconnectMessage = "disconnect"

    override init() {
        let peerID = MCPeerID(displayName: UIDevice.current.name)
        
        self.peerID = peerID
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: ChatManager.serviceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.session = session
    }
    
    func send(message msg: ChatMessage) {
        msg.senderID = currentUserID
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(msg) else { return }
        guard let session = self.session else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        
        print("[Send] PeerID: \(peerID.displayName) Message \(msg.body ?? "none")")
        
        DispatchQueue.main.async {
            self.onSendMessage.send(msg)
            self.onUpdateMessage.send(msg)
        }
    }
    
    func connect() {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.session = session
        session.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    func disconnect() {
        session?.disconnect()
        serviceAdvertiser.stopAdvertisingPeer()
        session = nil
    }
    
    func disconnectPeers() {
        guard let session = session else { return }
        try? session.send(disconnectMessage.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
    }
}

extension ChatManager: MCSessionDelegate {
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        if let msg = try? JSONDecoder().decode(ChatMessage.self, from: data) {
            print("[Receive] PeerID: \(peerID.displayName) Message \(msg.body ?? "none")")
            
            DispatchQueue.main.async {
                self.onRecieveMessage.send(msg)
                self.onUpdateMessage.send(msg)
            }
        } else if let sysCommand = String(data: data, encoding: .utf8) {
            print("[Receive] PeerID: \(peerID.displayName) Command \(sysCommand)")
            
            if sysCommand == disconnectMessage {
                DispatchQueue.main.async {
                    self.disconnect()
                    self.onRemoteDisconnect.send()
                }
                return
            }
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        //
    }
    
    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress) {
        //
    }
    
    
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?, withError error: Error?
    ) {
        //
    }
}

extension ChatManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        invitationHandler(true, session)
    }
}

fileprivate extension UIDevice {
    var userID: String {
        return identifierForVendor?.uuidString ?? "unknown"
    }
}
