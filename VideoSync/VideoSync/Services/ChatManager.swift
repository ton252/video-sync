//
//  ChatManager.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import Foundation
import MultipeerConnectivity

final class ChatManager: NSObject, ObservableObject {
    static let serviceType = "p2p-chat"
    static var currentUserID: String { return UIDevice.current.userID }
    
    let peerID: MCPeerID
    let session: MCSession
    
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
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        //
    }

    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        //
    }
    
    func session(
        _ session: MCSession,
        didReceive data: Data,
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
