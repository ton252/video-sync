//
//  ContentView.swift
//  VideoSync
//
//  Created by anton.poliakov on 08.04.2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var chatManager = ChatManager()
    
    @State var showBrowser = false
    @State var isChatHostPresented = false
    @State var isChatPeerPresented = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Начать хостинг") {
                    chatManager.startHosting()
                    isChatHostPresented = true
                }.padding()
                Spacer().frame(height: 8)
                Button("Присоединиться") {
                    chatManager.joinSession()
                    showBrowser = true
                }.padding()
            }
            .sheet(isPresented: $showBrowser) {
                MCBrowserViewControllerWrapper(
                    showBrowser: $showBrowser,
                    chatManager: chatManager
                ) {
                    isChatPeerPresented = true
                }
            }.navigationDestination(
                isPresented: $isChatHostPresented) {
                    ChatView(viewModel: ChatViewModel(chatManager: chatManager))
            }.navigationDestination(
                isPresented: $isChatPeerPresented) {
                    ChatView(viewModel: ChatViewModel(chatManager: chatManager))
            }
        }
    }
}

#Preview {
    ContentView()
}
