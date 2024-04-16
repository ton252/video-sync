//
//  ContentView.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import SwiftUI
import Combine

final class HomeViewModel: ObservableObject {
    @Published var showBrowser: Bool = false
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
    
    @StateObject var viewModel = HomeViewModel()
    @Environment(\.presentationMode) var presentationMode

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
                    viewModel.showBrowser.toggle()
                }.padding()
            }
            .sheet(isPresented: $viewModel.showBrowser) {
                HostBrowserView(
                    session: viewModel.chatManager.session!
                ) { success in
                    presentationMode.wrappedValue.dismiss()
                    viewModel.showBrowser.toggle()
                    
                    guard success else { return }
                    viewModel.navigationPath.append(Destination.peerScreen)
                }
            }.navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .hostScreen:
                    ChatView(isHost: true, chatManager: viewModel.chatManager).onDisappear() {
                        viewModel.chatManager.disconnectPeers()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.chatManager.disconnect()
                        }
                    }
                case .peerScreen:
                    ChatView(isHost: false, chatManager: viewModel.chatManager).onDisappear() {
                        viewModel.chatManager.disconnectPeers()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.chatManager.disconnect()
                        }
                    }
                }
            }
        }
    }
}
