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
    let session: MCSession
    var currentUserID: String { return UIDevice.current.userID }
    
    let onSendMessage = PassthroughSubject<ChatMessage, Never>()
    let onRecieveMessage = PassthroughSubject<ChatMessage, Never>()
    
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    
    override init() {
        let peerID = MCPeerID(displayName: UIDevice.current.name)
        
        self.peerID = peerID
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: ChatManager.serviceType)
        
        super.init()
        
        self.session.delegate = self
        self.serviceAdvertiser.delegate = self
    }
    
    func send(message msg: ChatMessage) {
        msg.senderID = currentUserID
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(msg) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        
        DispatchQueue.main.async {
            self.onSendMessage.send(msg)
        }
    }
    
    func startHosting() {
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    func stopHosting() {
        serviceAdvertiser.stopAdvertisingPeer()
    }
    
    func disconnectSession() {
        session.disconnect()
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
        let decoder = JSONDecoder()
        guard let msg = try? decoder.decode(ChatMessage.self, from: data) else { return }
        
        DispatchQueue.main.async {
            self.onRecieveMessage.send(msg)
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
