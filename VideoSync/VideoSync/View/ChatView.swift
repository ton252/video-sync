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

class ChatStateManager: ObservableObject {
    @Published var videoLink: String? = nil
}

struct ChatView: View {
    let connectionType: ChatConnectionType
    
    @ObservedObject private var chatManager = ChatManager()
    @ObservedObject private var chatStateManager = ChatStateManager()
    private let commandPerformer = CommandPerformer()
    
    @State private var isStreamer: Bool = false
    @State private var messageText: String = ""
    @State private var commands = [
        CommandItem(command: "/start_video"),
    ]
    
    @FocusState private var isTextFieldFocused: Bool
    
    
    init(connectionType: ChatConnectionType) {
        UIScrollView.appearance().alwaysBounceVertical = false
        self.connectionType = connectionType
        self.setupBindings()
    }
    
    var body: some View {
        return VStack {
            YouTubeView(videoLink: Binding<String?>(
                get: { chatStateManager.videoLink },
                set: { chatStateManager.videoLink = $0 }
            ))
            .aspectRatio(16/9, contentMode: .fit)
            .layoutPriority(1)
            ScrollView() {
                ForEach(
                    chatManager.messages
                        .filter() { $0.type == .message }
                        .map() { $0.body ?? "" },
                    id: \.self) { message in
                        Text(message).padding()
                    }
                    .frame(width: UIScreen.main.bounds.width)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                dismissKeyboard()
            }
            CommandPanel(items: $commands) { item in
                messageText += "\(item.command) "
                if !isTextFieldFocused {
                    isTextFieldFocused = true
                }
            }
            HStack {
                TextField("Введите сообщение здесь", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                Button("Отправить") {
                    chatManager.sendMessage(MessageModel(body: messageText))
                    messageText = ""
                }
            }.padding(EdgeInsets(top: 4, leading: 16, bottom: 16, trailing: 16))
        }
        .navigationTitle("Chat")
    }
    
    private func dismissKeyboard() {
        isTextFieldFocused = false
    }
    
    private func setupBindings() {
        chatManager.onMessageUpdate = { message in
            self.commandPerformer.perform(message: message)
        }
        commandPerformer.onUpdateVideoLink = { message, videoLink in
            self.chatStateManager.videoLink = videoLink
        }
    }
}
