//
//  ContentView.swift
//  VideoSync
//
//  Created by anton.poliakov on 08.04.2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var chatManager = ChatManager()
    @State var isChatPresented = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Начать хостинг") {
                    chatManager.startHosting()
                    isChatPresented = true
                }.padding()
                Spacer().frame(height: 8)
                Button("Присоединиться") {
                    chatManager.joinSession()
                }.padding()
            }
            .sheet(isPresented: $chatManager.showBrowser) {
                MCBrowserViewControllerWrapper(chatManager: chatManager) {
                    isChatPresented = true
                }
            }.navigationDestination(
                isPresented: $isChatPresented) {
                    ChatView()
            }
        }
    }
}

struct ChatView: View {
    @ObservedObject var chatManager = ChatManager()
    @State private var messageText: String = ""
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(chatManager.messages, id: \.self) { message in
                    Text(message).padding()
                }.frame(width: UIScreen.main.bounds.width)
            }
            
            HStack {
                TextField("Введите сообщение здесь", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Отправить") {
                    chatManager.sendMessage(messageText)
                    messageText = ""
                }
            }.padding()
        }
        .navigationTitle("Chat")
        .sheet(isPresented: $chatManager.showBrowser) {
            MCBrowserViewControllerWrapper(chatManager: chatManager)
        }
    }
}

#Preview {
    ContentView()
}
