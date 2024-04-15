//
//  ChatManager.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import Foundation
import MultipeerConnectivity
import Combine

class ChatManager: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate {
    var peerID: MCPeerID
    var mcSession: MCSession
    var serviceAdvertiser: MCNearbyServiceAdvertiser?
    let onMessageUpdate = PassthroughSubject<MessageModel, Never>()
    let onStateDidChanged = PassthroughSubject<(MCPeerID, MCSessionState), Never>()
    
    var currentUserID: String {
        return UIDevice.current.userId
    }
        
    override init() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        self.mcSession.delegate = self
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "p2p-chat")
        self.serviceAdvertiser?.delegate = self
    }
        
    func startHosting() {
        serviceAdvertiser?.startAdvertisingPeer()
    }
    
    func stopHosting() {
        serviceAdvertiser?.stopAdvertisingPeer()
    }
    
    func joinSession() {
        //
    }
    
    func sendMessage(_ message: MessageModel) {
        message.id = UUID().uuidString
        message.senderID = currentUserID
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(message) else { return }
        try? mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
        
        DispatchQueue.main.async {
            self.onMessageUpdate.send(message)
        }
    }
    
    func isMessageOutgoing(_ message: MessageModel) -> Bool {
        return message.senderID == currentUserID
    }
    
    // MARK: MCSessionDelegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
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
        onStateDidChanged.send((peerID, state))
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let decoder = JSONDecoder()
        guard let message = try? decoder.decode(MessageModel.self, from: data) else { return }
        
        DispatchQueue.main.async {
            self.onMessageUpdate.send(message)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
    // MARK: MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.mcSession)
    }
}

fileprivate extension UIDevice {
    var userId: String {
        return identifierForVendor?.uuidString ?? "unknown"
    }
}
