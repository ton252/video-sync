////
////  ContentView.swift
////  VideoSync
////
////  Created by anton.poliakov on 08.04.2024.
////
//
//import SwiftUI
//
//class ContentViewModel: ObservableObject  {
//    @Published var text = "Text"
//    let delayObject = MockDelayClass()
//    
//    init() {
//        prepare()
//    }
//    
//    private func prepare() {
//        delayObject.completion = { [weak self] in
//            self?.text = "New Text"
//        }
//    }
//    
//    func perform() {
//        delayObject.perform(after: 1.0)
//    }
//}
//
//class MockDelayClass: NSObject {
//    var completion: (() -> ())?
//    private let queue = DispatchQueue.global(qos: .background)
//    
//    func perform(after: TimeInterval) {
//        queue.asyncAfter(deadline: .now() + after) { [weak self] in
//            DispatchQueue.main.async {
//                self?.completion?()
//            }
//        }
//    }
//}
//
//struct ContentView: View {
//    var viewModel = ContentViewModel()
//    @State var isPresented: Bool = false
//    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                Button("Tap") {
//                    isPresented = true
//                }
//            }
//            .navigationDestination(isPresented: $isPresented) {
//                NewView(viewModel: viewModel)
//            }
//        }
//    }
//}
//
//struct NewView: View {
//    @ObservedObject var viewModel: ContentViewModel
//    
//    var body: some View {
//        VStack {
//            Text(viewModel.text)
//            Spacer()
//            Button("Tap") {
//                viewModel.perform()
//            }
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//}
