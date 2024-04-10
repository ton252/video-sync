//
//  MCBrowserView.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import SwiftUI
import MultipeerConnectivity


// MARK: - MCBrowserViewControllerWrapper
struct MCBrowserViewControllerWrapper: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var chatManager: ChatManager
    var onComplete: (() -> ())?

    func makeUIViewController(context: Context) -> MCBrowserViewController {
        let browser = MCBrowserViewController(serviceType: "p2p-chat", session: chatManager.mcSession)
        browser.delegate = chatManager
        return browser
    }
    
    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) { 
        //
    }
    
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
            parent.onComplete?()
        }
    }
}
