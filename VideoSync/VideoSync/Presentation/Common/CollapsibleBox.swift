//
//  CollapsibleBox.swift
//  VideoSync
//
//  Created by ton252 on 16.04.2024.
//

import SwiftUI

struct CollapsibleBox<Content: View>: View {
    @Binding var isOpened: Bool
    var content: () -> Content
    
    var body: some View {
        VStack {
            if isOpened {
                content()
                .frame(maxWidth: UIScreen.main.bounds.width)
            } else {
                content()
                .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 0)
            }
        }
        .clipped()
    }
}
