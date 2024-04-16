//
//  ChatView.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    var body: some View {
        return ZStack {
            Color.sGrey.edgesIgnoringSafeArea(.bottom)
            Color.white
            VStack(spacing: 0) {
                CollapsibleBox(isOpened: $viewModel.isPlayerOpened) {
                    Color.black
                        .aspectRatio(16/9, contentMode: .fit)
                        .layoutPriority(1)
                }
                ScrollView() {
                    VStack(spacing: 16) {
                        ForEach(viewModel.messages, id: \.id) { msg in
                            let isOutgoing = viewModel.isOutgoingMessage(msg)
                            MessageView(
                                text: msg.body,
                                type: msg.type,
                                isOutgoing: isOutgoing
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
                    viewModel.messageInput += "\(item.command) "
                    if !isTextFieldFocused {
                        isTextFieldFocused = true
                    }
                }
                HStack(spacing: 0) {
                    TextField("Enter message", text: Binding<String>(
                        get: { viewModel.messageInput },
                        set: { viewModel.messageInput = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .padding(.trailing, 16)
                    Button(action: {
                        viewModel.sendMessage()
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
            .navigationTitle(viewModel.title)
            .onAppear() {
                viewModel.onAppear()
            }
        }
    }
    
    private func dismissKeyboard() {
        isTextFieldFocused = false
    }
}
