//
//  ChatView.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import SwiftUI

enum ChatConnectionType {
    case host
    case peer
}

struct ChatView: View {
    let connectionType: ChatConnectionType
    @ObservedObject var chatManager = ChatManager()
    @State private var messageText: String = ""
    @State private var videoLink: String? = "https://youtu.be/uNiQJhz7iQU?si=BkVMrOVTfQMYmhDZ"
    
    var body: some View {
        VStack {
            YouTubeView(videoLink: $videoLink)
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