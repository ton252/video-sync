//
//  ContentView.swift
//  VideoSync
//
//  Created by anton.poliakov on 08.04.2024.
//

import SwiftUI
import MultipeerConnectivity

// MARK: - ChatManager
class ChatManager: NSObject, ObservableObject, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {
    @Published var messages: [String] = []
    @Published var showBrowser = false

    var peerID: MCPeerID
    var mcSession: MCSession
    var serviceAdvertiser: MCNearbyServiceAdvertiser?
    
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

// MARK: - MCBrowserViewControllerWrapper
struct MCBrowserViewControllerWrapper: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var chatManager: ChatManager

    func makeUIViewController(context: Context) -> MCBrowserViewController {
        let browser = MCBrowserViewController(serviceType: "p2p-chat", session: chatManager.mcSession)
        browser.delegate = chatManager
        return browser
    }
    
    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, chatManager: chatManager)
    }
    
    class Coordinator: NSObject, MCBrowserViewControllerDelegate {
        var parent: MCBrowserViewControllerWrapper
        var chatManager: ChatManager
        
        init(_ parent: MCBrowserViewControllerWrapper, chatManager: ChatManager) {
            self.parent = parent
            self.chatManager = chatManager
        }
        
        func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
            parent.presentationMode.wrappedValue.dismiss()
            chatManager.showBrowser = false
        }
        
        func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
            parent.presentationMode.wrappedValue.dismiss()
            chatManager.showBrowser = false
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @ObservedObject var chatManager = ChatManager()
    @State private var messageText: String = ""
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(chatManager.messages, id: \.self) { message in
                    Text(message).padding()
                }
            }
            
            HStack {
                TextField("Введите сообщение здесь", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Отправить") {
                    chatManager.sendMessage(messageText)
                    messageText = ""
                }
            }.padding()
            
            HStack {
                Button("Начать хостинг") {
                    chatManager.startHosting()
                }
                Button("Присоединиться") {
                    chatManager.joinSession()
                }
            }.padding()
        }
        .sheet(isPresented: $chatManager.showBrowser) {
            MCBrowserViewControllerWrapper(chatManager: chatManager)
        }
    }
}


//import SwiftUI
//import MultipeerConnectivity
//import AVKit
//import Network
//
//class ChatManager: NSObject, ObservableObject, MCSessionDelegate, MCBrowserViewControllerDelegate, MCAdvertiserAssistantDelegate {
//    @Published var messages: [String] = []
//    @Published var showBrowser = false
//
//    var peerID: MCPeerID
//    var mcSession: MCSession
//    var mcAdvertiserAssistant: MCAdvertiserAssistant?
//    
//    override init() {
//        self.peerID = MCPeerID(displayName: UIDevice.current.name)
//        self.mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
//        super.init()
//        self.mcSession.delegate = self
//    }
//    
//    func startHosting() {
//        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "p2p-chat", discoveryInfo: nil, session: mcSession)
//        mcAdvertiserAssistant?.start()
//    }
//    
//    func joinSession() {
//        showBrowser = true
//    }
//    
//    func sendMessage(_ message: String) {
//        guard let data = message.data(using: .utf8) else { return }
//        try? mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
//        DispatchQueue.main.async {
//            self.messages.append("Я: \(message)")
//        }
//    }
//    
//    // MARK: MCSessionDelegate
//    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
//        switch state {
//            case .connected:
//                print("Connected: \(peerID.displayName)")
//            case .connecting:
//                print("Connecting: \(peerID.displayName)")
//            case .notConnected:
//                print("Not Connected: \(peerID.displayName)")
//            @unknown default:
//                print("Unknown state received: \(peerID.displayName)")
//        }
//    }
//    
//    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//        if let message = String(data: data, encoding: .utf8) {
//            DispatchQueue.main.async {
//                self.messages.append("\(peerID.displayName): \(message)")
//            }
//        }
//    }
//    
//    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
//        //
//    }
//    
//    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
//        //
//    }
//    
//    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { 
//        //
//    }
//    
//    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
//        certificateHandler(true)
//    }
//    
//    // MARK: MCBrowserViewControllerDelegate
//    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
//        showBrowser = false
//    }
//    
//    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
//        showBrowser = false
//    }
//}
//
//struct MCBrowserViewControllerWrapper: UIViewControllerRepresentable {
//    @Environment(\.presentationMode) var presentationMode
//    @ObservedObject var chatManager: ChatManager
//
//    func makeUIViewController(context: Context) -> MCBrowserViewController {
//        let browser = MCBrowserViewController(serviceType: "p2p-chat", session: chatManager.mcSession)
//        browser.delegate = chatManager
//        return browser
//    }
//    
//    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) { }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self, chatManager: chatManager)
//    }
//    
//    class Coordinator: NSObject, MCBrowserViewControllerDelegate {
//        var parent: MCBrowserViewControllerWrapper
//        var chatManager: ChatManager
//        
//        init(_ parent: MCBrowserViewControllerWrapper, chatManager: ChatManager) {
//            self.parent = parent
//            self.chatManager = chatManager
//        }
//        
//        func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
//            parent.presentationMode.wrappedValue.dismiss()
//            chatManager.showBrowser = false
//        }
//        
//        func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
//            parent.presentationMode.wrappedValue.dismiss()
//            chatManager.showBrowser = false
//        }
//    }
//}
//
//struct ContentView: View {
//    @ObservedObject var chatManager = ChatManager()
//    @State private var messageText: String = ""
//    
//    var body: some View {
//        VStack {
//            ScrollView {
//                ForEach(chatManager.messages, id: \.self) { message in
//                    Text(message).padding()
//                }
//            }
//            
//            HStack {
//                TextField("Введите сообщение здесь", text: $messageText)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                Button("Отправить") {
//                    chatManager.sendMessage(messageText)
//                    messageText = ""
//                }
//            }.padding()
//            
//            HStack {
//                Button("Начать хостинг") {
//                    chatManager.startHosting()
//                }
//                Button("Присоединиться") {
//                    chatManager.joinSession()
//                }
//            }.padding()
//        }
//        .sheet(isPresented: $chatManager.showBrowser) {
//            MCBrowserViewControllerWrapper(chatManager: chatManager)
//            
//        }
//    }
//}

//struct ContentView: View {
//    var body: some View {
//        NavigationStack {
//            VStack {
//                Button("Server") {
//                    print("Tap Server")
//                }
//                .frame(width: 200)
//                .foregroundColor(Color.blue) // Text color
//                .padding() // Add padding around the text
//                .background(Color.white) // Button background color
//                .cornerRadius(10) // Corner radius
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10) // Match this corner radius with the button's
//                        .stroke(Color.blue, lineWidth: 2) // Border color and width
//                )
//                Spacer().frame(height: 16)
//                Button("Client") {
//                    print("Tap Server")
//                }
//                .frame(width: 200)
//                .foregroundColor(Color.blue) // Text color
//                .padding() // Add padding around the text
//                .background(Color.white) // Button background color
//                .cornerRadius(10) // Corner radius
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10) // Match this corner radius with the button's
//                        .stroke(Color.blue, lineWidth: 2) // Border color and width
//                )
//            }
//            .navigationTitle("Sync Videos")
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//    
//}

#Preview {
    ContentView()
}
