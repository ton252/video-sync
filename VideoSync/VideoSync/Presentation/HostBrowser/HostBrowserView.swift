//
//  MCBrowserView.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import SwiftUI
import MultipeerConnectivity

struct HostBrowserView: UIViewControllerRepresentable {
    let session: MCSession
    
    var onComplete: ((Bool) -> ())?

    func makeUIViewController(context: Context) -> MCBrowserViewController {
        let browser = MCBrowserViewController(
            serviceType: ChatManager.serviceType,
            session: session
        )
        browser.delegate = context.coordinator
        return browser
    }
    
    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) { 
        //
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MCBrowserViewControllerDelegate {
        var parent: HostBrowserView
        
        init(_ parent: HostBrowserView) {
            self.parent = parent
        }
        
        func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
            parent.onComplete?(true)
        }
        
        func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
            parent.onComplete?(false)
        }
    }
}

//HostBrowserView(
//    session: chatManager.session!
//) { success in
//    guard success else { return }
//    viewModel.showBrowser.toggle()
//    viewModel.navigationPath.append(Destination.peerScreen)
//}
