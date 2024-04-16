//
//  ContentView.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import SwiftUI
import Combine

struct HomeView: View {
    enum Destination {
        case hostScreen
        case peerScreen
    }
    
    @State var showBrowser = false
    @State private var navigationPath = NavigationPath()
    
    private let chatManager = ChatManager()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Button("Start hosting") {
                    chatManager.startHosting()
                    navigationPath.append(Destination.hostScreen)
                }.padding()
                Spacer().frame(height: 8)
                Button("Connect") {
                    showBrowser.toggle()
                }.padding()
            }
            .sheet(isPresented: $showBrowser) {
                HostBrowserView(showBrowser: $showBrowser, chatManager: chatManager) { success in
                    guard success else { return }
                    navigationPath.append(Destination.peerScreen)
                }
            }.navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .hostScreen:
                    let viewModel = ChatViewModel(
                        isHost: true,
                        chatManager: chatManager
                    )
                    ChatView(viewModel: viewModel)
                case .peerScreen:
                    let viewModel = ChatViewModel(
                        isHost: false,
                        chatManager: chatManager
                    )
                    ChatView(viewModel: viewModel)
                }
            }
        }
    }
}
