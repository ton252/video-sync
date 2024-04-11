//
//  ChatView.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var videoLink: String? = nil
    @Published var messages: [MessageModel] = []
    
    var filtredMessages: [MessageModel] {
        return messages.filter() { $0.type == .message }
    }
    
    @Published fileprivate var messageText: String = ""
    @Published fileprivate var commands = [
        CommandItem(command: "/start_video"),
    ]
    
    private let chatManager: ChatManager
    private let commandPerformer = CommandPerformer()
    private var cancellable: [AnyCancellable] = []
    
    init(chatManager: ChatManager) {
        self.chatManager = chatManager
        setupBindings()
    }
    
    deinit {
        cancellable.forEach() { $0.cancel() }
    }
    
    private func setupBindings() {
        let messageSubs = chatManager.onMessageUpdate.sink { [weak self] message in
            self?.messages.append(message)
            self?.commandPerformer.perform(message: message)
        }
        cancellable.append(messageSubs)
        commandPerformer.onUpdateVideoLink = { [weak self] message, videoLink in
            self?.videoLink = videoLink
        }
    }
    
    func sendMessage(_ msg: MessageModel) {
        chatManager.sendMessage(msg)
    }
    
    func clear() {
        videoLink = nil
        messages = []
    }
    
    func isMessageOutgoing(_ message: MessageModel) -> Bool {
        return chatManager.isMessageOutgoing(message)
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
                    VStack(spacing: 16) {
                        ForEach(viewModel.filtredMessages, id: \.id) { message in
                            MessageView(
                                text: message.body,
                                isOutgoing: viewModel.isMessageOutgoing(message)
                            ).padding(.zero)
                        }
                    }
                    .padding(.top, 16)
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
