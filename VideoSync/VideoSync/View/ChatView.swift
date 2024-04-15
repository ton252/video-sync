//
//  ChatView.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import SwiftUI
import Combine

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
                CollapsibleBox(isOpened: $viewModel.isPlayerOpened) {
//                    Color.black
//                        .aspectRatio(16/9, contentMode: .fit)
//                        .layoutPriority(1)
                    YouTubeView(videoLink: Binding<String?>(
                        get: { viewModel.videoLink },
                        set: { viewModel.videoLink = $0 }
                    ), allowContols: Binding<Bool>(
                        get: { viewModel.allowPlayerControl },
                        set: { viewModel.allowPlayerControl = $0 }
                    ), controller: viewModel.videoController)
                    .aspectRatio(16/9, contentMode: .fit)
                    .layoutPriority(1)
                }
                ScrollView() {
                    VStack(spacing: 16) {
                        ForEach(viewModel.filtredMessages, id: \.id) { message in
                            MessageView(
                                text: message.body,
                                type: message.type,
                                isOutgoing: viewModel.isMessageOutgoing(message)
                            ).padding(.zero)
                        }
                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
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
                        guard !viewModel.messageText.isEmpty else { return }
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
        }
    }
    
    private func dismissKeyboard() {
        isTextFieldFocused = false
    }
}

class ChatViewModel: ObservableObject {
    @Published var videoLink: String? = nil
    @Published var messages: [MessageModel] = []
    @Published var allowPlayerControl: Bool = false
    @Published var isPlayerOpened: Bool = false
    
    let videoController = YouTubeWebViewController()
    
    var filtredMessages: [MessageModel] {
        return messages.filter() { $0.type != .system && $0.body?.isEmpty == false }
    }
    
    @Published fileprivate var messageText: String = ""
    @Published fileprivate var commands = [
        CommandItem(command: "/start_video"),
        CommandItem(command: "/stop_video"),
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
        let currentUserID = chatManager.currentUserID
        let messageSubs = chatManager.onMessageUpdate.sink { [weak self] message in
            self?.messages.append(message)
            self?.commandPerformer.perform(message: message)
        }
        cancellable.append(messageSubs)
        commandPerformer.onVideoStart = { [weak self] message, videoLink in
            let extractor = YouTubeExtractor()
            guard extractor.isValidLink(videoLink) else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.messages.append(MessageModel(body: "Invalid link", type: .error))
                }
                return
            }
            
            self?.videoLink = videoLink
            self?.allowPlayerControl = message.senderID == currentUserID
            if self?.videoLink == videoLink {
                self?.videoController.restart()
            }
            withAnimation() {
                self?.isPlayerOpened = true
            }
        }
        commandPerformer.onVideoStop = { [weak self] message in
            guard currentUserID == message.senderID else { return }
            guard self?.videoLink != nil else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.messages.append(MessageModel(body: "No playing video", type: .error))
                }
                return
            }
            self?.videoLink = nil
            
            withAnimation() {
                self?.isPlayerOpened = false
            }
        }
    }
    
    func sendMessage(_ msg: MessageModel) {
        chatManager.sendMessage(msg)
    }
    
    func clear() {
        messageText = ""
        isPlayerOpened = false
        videoLink = nil
        messages = []
    }
    
    func isMessageOutgoing(_ message: MessageModel) -> Bool {
        return chatManager.isMessageOutgoing(message)
    }
}
