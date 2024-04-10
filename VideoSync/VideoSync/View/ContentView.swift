//
//  ContentView.swift
//  VideoSync
//
//  Created by anton.poliakov on 08.04.2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var chatManager = ChatManager()
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
                }.padding()
            }
            .sheet(isPresented: $chatManager.showBrowser) {
                MCBrowserViewControllerWrapper(chatManager: chatManager) {
                    isChatPeerPresented = true
                }
            }.navigationDestination(
                isPresented: $isChatHostPresented) {
                    ChatView(connectionType: .host)
            }.navigationDestination(
                isPresented: $isChatPeerPresented) {
                    ChatView(connectionType: .peer)
            }
        }
    }
}

#Preview {
    ContentView()
}
