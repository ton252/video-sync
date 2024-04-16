//
//  ContentView.swift
//  VideoSync
//
//  Created by anton.poliakov on 08.04.2024.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var chatManager = ChatManager()
    
    enum Destination {
        case hostScreen
        case peerScreen
    }
    
    @State var showBrowser = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Button("Start hosting") {
                    chatManager.startHosting()
                    navigationPath.append(Destination.hostScreen)
                }.padding()
                Spacer().frame(height: 8)
                Button("Connect") {
                    chatManager.joinSession()
                    showBrowser.toggle()
                }.padding()
            }
            .sheet(isPresented: $showBrowser) {
                MCBrowserViewControllerWrapper(
                    showBrowser: $showBrowser,
                    chatManager: chatManager
                ) {
                    navigationPath.append(Destination.peerScreen)
                }
            }.navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .hostScreen:
                    let chatViewModel = ChatViewModel(isHost: true, chatManager: chatManager)
                    ChatView(viewModel: chatViewModel).onDisappear() {
                        chatManager.stopHosting()
                        chatManager.disconnectSession()
                    }
                case .peerScreen:
                    let chatViewModel = ChatViewModel(isHost: false, chatManager: chatManager)
                    ChatView(viewModel: chatViewModel).onDisappear() {
                        chatManager.disconnectSession()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
