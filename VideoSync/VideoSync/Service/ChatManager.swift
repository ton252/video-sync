//
//  ChatManager.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import Foundation
import MultipeerConnectivity

class ChatManager: NSObject, ObservableObject, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {
    @Published var messages: [String] = []
    @Published var showBrowser = false
    
    var peerID: MCPeerID
    var mcSession: MCSession
    var serviceAdvertiser: MCNearbyServiceAdvertiser?
    
    static let shared = ChatManager()
    
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
        showBrowser = true
    }
    
    func sendMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        try? mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
        
        DispatchQueue.main.async {
            self.messages.append("Я: \(message)")
        }
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
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.messages.append("\(peerID.displayName): \(message)")
            }
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
    
    // MARK: MCBrowserViewControllerDelegate
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        showBrowser = false
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        showBrowser = false
    }
}