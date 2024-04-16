//
//  MessageView.swift
//  VideoSync
//
//  Created by ton252 on 12.04.2024.
//

import SwiftUI

struct MessageView: View {
    let text: String?
    let isOutgoing: Bool
    let type: ChatMessageType
    
    init(
        text: String? = nil,
        type: ChatMessageType = .message,
        isOutgoing: Bool
    ) {
        self.text = text
        self.isOutgoing = isOutgoing
        self.type = type
    }
    
    private var isError: Bool {
        return type == .error
    }
    
    var body: some View {
        HStack {
            if isOutgoing {
                Spacer()
            }
            
            Text(text ?? "")
                .padding(10)
                .foregroundColor(.white)
                .background(isError ? Color.red : (isOutgoing ? Color.blue : Color.gray))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .fixedSize(horizontal: false, vertical: true)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = text
                    }) {
                        Text("Copy")
                        Image(systemName: "doc.on.doc")
                    }
                }
                .onTapGesture(count: 2) {
                    UIPasteboard.general.string = text
                    print("Text copied to clipboard")
                }
            
            if !isOutgoing {
                Spacer()
            }
        }
    }
}
