//
//  ChatView.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        viewModel.isHost ? Color.blue : Color.red
    }
}
