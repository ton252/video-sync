//
//  ContentView.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import SwiftUI
import Combine

final class HomeViewModel: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    let chatManager = ChatManager()
    private var cancellable: [Cancellable] = []
    
    init() {
        let subs = chatManager.onRemoteDisconnect.sink { _ in
            self.navigationPath.removeLast()
        }
        cancellable.append(subs)
    }
    
    deinit {
        cancellable.forEach() { $0.cancel() }
    }
}

struct HomeView: View {
    enum Destination {
        case hostScreen
        case peerScreen
    }
    
    @State var showBrowser = false
    @ObservedObject var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            VStack {
                Button("Start hosting") {
                    viewModel.chatManager.connect()
                    viewModel.navigationPath.append(Destination.hostScreen)
                }.padding()
                Spacer().frame(height: 8)
                Button("Connect") {
                    viewModel.chatManager.connect()
                    showBrowser.toggle()
                }.padding()
            }
            .sheet(isPresented: $showBrowser) {
                HostBrowserView(
                    session: viewModel.chatManager.session!,
                    showBrowser: $showBrowser
                ) { success in
                    guard success else { return }
                    showBrowser.toggle()
                    viewModel.navigationPath.append(Destination.peerScreen)
                }
            }.navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .hostScreen:
                    let vm = ChatViewModel(
                        isHost: true,
                        chatManager: viewModel.chatManager
                    )
                    ChatView(viewModel: vm).onDisappear() {
                        viewModel.chatManager.disconnectPeers()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.chatManager.disconnect()
                        }
                    }
                case .peerScreen:
                    let vm = ChatViewModel(
                        isHost: false,
                        chatManager: viewModel.chatManager
                    )
                    ChatView(viewModel: vm).onDisappear() {
                        viewModel.chatManager.disconnect()
                    }
                }
            }
        }
    }
}
