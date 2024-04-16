//
//  MCBrowserView.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import SwiftUI
import MultipeerConnectivity

struct HostBrowserView: UIViewControllerRepresentable {
    @Binding var showBrowser: Bool
    @ObservedObject var chatManager: ChatManager
    @Environment(\.presentationMode) var presentationMode
    
    var onComplete: ((Bool) -> ())?

    func makeUIViewController(context: Context) -> MCBrowserViewController {
        let browser = MCBrowserViewController(
            serviceType: ChatManager.serviceType,
            session: chatManager.session
        )
        browser.delegate = context.coordinator
        return browser
    }
    
    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) { 
        //
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, chatManager: chatManager)
    }
    
    class Coordinator: NSObject, MCBrowserViewControllerDelegate {
        var parent: HostBrowserView
        var chatManager: ChatManager
        
        init(_ parent: HostBrowserView, chatManager: ChatManager) {
            self.parent = parent
            self.chatManager = chatManager
        }
        
        func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.showBrowser = false
            parent.onComplete?(true)
        }
        
        func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.showBrowser = false
            parent.onComplete?(false)
        }
    }
    
}
