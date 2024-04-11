//
//  CommandPanel.swift
//  VideoSync
//
//  Created by ton252 on 11.04.2024.
//

import SwiftUI


struct CommandItem {
    let id: String
    let command: String
    let displayName: String
    
    init(command: String, displayName: String? = nil) {
        self.command = command
        self.displayName = displayName ?? command
        self.id = UUID().uuidString
    }
}

struct CommandPanel: View {
    @Binding var items: [CommandItem]
    var onTap: ((CommandItem) -> ())?
    
    var body: some View {
        VStack {
            Color.gray.opacity(0.1).frame(height: 1)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(items, id: \.id) { item in
                        Button(action: {
                            onTap?(item)
                        }) {
                            Text(item.displayName)
                                .padding()
                                .foregroundColor(.blue)
                        }
                        .frame(height: 30)
                    }
                }
                .padding()
                .frame(height: 32)
            }
            Color.gray.opacity(0.1).frame(height: 1)
        }
        .background(Color.white)
    }
}
