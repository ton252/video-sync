//
//  ChatView.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var videoLink: String? = nil
    @Published var messages: [MessageModel] = []
    @Published var chatManager: ChatManager
    
    var filtredMessages: [MessageModel] {
        return messages.filter() { $0.type == .message }
    }
    
    @Published fileprivate var messageText: String = ""
    @Published fileprivate var commands = [
        CommandItem(command: "/start_video"),
    ]
    
    private let commandPerformer = CommandPerformer()
    
    init(chatManager: ChatManager) {
        self.chatManager = chatManager
        setupBindings()
    }
    
    private func setupBindings() {
        chatManager.onMessageUpdate = { [weak self] message in
            self?.messages.append(message)
            self?.commandPerformer.perform(message: message)
        }
        commandPerformer.onUpdateVideoLink = { [weak self] message, videoLink in
            self?.videoLink = videoLink
        }
    }
    
    func sendMessage(_ msg: MessageModel) {
        messages.append(msg)
        chatManager.sendMessage(msg)
    }
    
    func clear() {
        videoLink = nil
        messages = []
    }
}

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    init(viewModel: ChatViewModel) {
        UIScrollView.appearance().alwaysBounceVertical = false
        self.viewModel = viewModel
    }
    
    var body: some View {
        return ZStack {
            Color(hex: "F5F5F5").edgesIgnoringSafeArea(.bottom)
            Color.white
            VStack(spacing: 0) {
                YouTubeView(videoLink: Binding<String?>(
                    get: { viewModel.videoLink },
                    set: { viewModel.videoLink = $0 }
                ))
                .aspectRatio(16/9, contentMode: .fit)
                .layoutPriority(1)
                ScrollView() {
                    ForEach(viewModel.filtredMessages, id: \.id) { message in
                        Text(message.body ?? "").padding()
                    }
                    .frame(width: UIScreen.main.bounds.width)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    dismissKeyboard()
                }
                CommandPanel(items: Binding<[CommandItem]>(
                    get: { viewModel.commands },
                    set: { viewModel.commands = $0 }
                )) { item in
                    viewModel.messageText += "\(item.command) "
                    if !isTextFieldFocused {
                        isTextFieldFocused = true
                    }
                }
                HStack(spacing: 0) {
                    TextField("Enter message", text: Binding<String>(
                        get: { viewModel.messageText },
                        set: { viewModel.messageText = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .padding(.trailing, 16)
                    Button(action: {
                        viewModel.sendMessage(MessageModel(body: viewModel.messageText))
                        viewModel.messageText = ""
                    }) {
                        Text("Send")
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                    }
                    .frame(height: 34)
                    .padding(.horizontal, 16)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding(EdgeInsets(top: 4, leading: 16, bottom: 16, trailing: 16))
                .background(Color(hex: "F5F5F5"))
            }
            .navigationTitle("Chat")
            .onDisappear() {
                viewModel.clear()
            }
        }
    }
    
    private func dismissKeyboard() {
        isTextFieldFocused = false
    }
}
