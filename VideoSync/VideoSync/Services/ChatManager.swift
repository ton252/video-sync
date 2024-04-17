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
        let package = ChatPackage(
            type: .userMessage,
            message: msg,
            command: nil
        )
        send(package: package)
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
        let package = ChatPackage(
            type: .system,
            command: .disconnectPeers
        )
        send(package: package)
    }
    
    private func send(package: ChatPackage) {
        package.id = UUID().uuidString
        guard let data = try? JSONEncoder().encode(package) else { return }
        guard let session = self.session else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
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
        guard let package = try? JSONDecoder().decode(ChatPackage.self, from: data) else { return }
        
        switch package.type {
        case .system:
            guard let command = package.command else { return }
            switch command {
            case .disconnectPeers:
                onRemoteDisconnect.send()
            }
            return
        case .userMessage:
            guard let msg = package.message else { return }
            DispatchQueue.main.async {
                self.onRecieveMessage.send(msg)
                self.onUpdateMessage.send(msg)
            }
            return
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
