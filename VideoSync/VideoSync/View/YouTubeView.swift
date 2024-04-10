//
//  YouTubeView.swift
//  VideoSync
//
//  Created by ton252 on 10.04.2024.
//

import SwiftUI
import WebKit

struct YouTubeView: View {
    @Binding var videoLink: String?
    @State var isPlaying: Bool = false
    
    var body: some View {
        ZStack {
            Color.black
            if let videoLink = videoLink {
                YouTubeWebView(videoLink: Binding.constant(videoLink), isPlaying: $isPlaying)
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.isPlaying = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                self.isPlaying = false
            }
        }
    }
}

enum PlayerState: String {
    case unstarted
    case ended
    case playing
    case paused
    case buffering
}

struct PlayerVars {
    var autoplay: Int = 1
    var playsinline: Int = 1
}

//class YouTubePlayerViewModel: ObservableObject {
//    @Published var videoLink: String
//    @Published var playerVars: PlayerVars
//    @Published var playerState: PlayerState = .unstarted
//    
//    init(videoLink: String, playerVars: PlayerVars) {
//        self.videoLink = videoLink
//        self.playerVars = playerVars
//    }
//    
//    func play() {
//
//    }
//    
//    
//    
//    var videoLink: String
//    var playerVars: PlayerVars
//    
//    func play() {
//        
//    }
//    
//    func stop() {
//        
//    }
//    
//    func seekTo(_ time: TimeInterval) {
//        
//    }
//}

struct YouTubeWebView: UIViewRepresentable {
    @Binding var videoLink: String
    @Binding var autoplay: Int
    @Binding var playsinline: Int
    @Binding var isPlaying: Bool
        
    private(set) var state: PlayerState?
    var onStateChange: ((PlayerState) -> ())?
        
    var videoId: String? {
        return extractVideoId(from: videoLink)
    }
        
    init(
        videoLink: Binding<String>,
        autoplay: Binding<Int> = .constant(1),
        playsinline: Binding<Int> = .constant(1),
        isPlaying: Binding<Bool> = .constant(false),
        onStateChange: ((PlayerState) -> ())? = nil
    ) {
        self._videoLink = videoLink
        self._autoplay = autoplay
        self._playsinline = playsinline
        self._isPlaying = isPlaying
        self.onStateChange = onStateChange
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: webViewConfig(context: context))
        context.coordinator.webView = webView
        updatePreviousValues(context: context)
        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.previousAutoplay != autoplay ||
            context.coordinator.previousPlaysinline != playsinline ||
            context.coordinator.previousVideoLink != videoLink
        {
            updatePreviousValues(context: context)
            uiView.loadHTMLString(htmlString, baseURL: nil)
        }
        
        if  isPlaying && state != .playing {
            uiView.evaluateJavaScript("document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":\"\"}', '*')", completionHandler: nil)
        } else if !isPlaying && state != .paused {
            uiView.evaluateJavaScript("document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"pauseVideo\",\"args\":\"\"}', '*')", completionHandler: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func webViewConfig(context: Context) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "youtubePlayerUpdate")
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        return configuration
    }
    
    var htmlString: String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background-color: #FFFFFF;
                    color: white;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                }
                #player {
                    width: 100%;
                    height: 100vh;
                }
            </style>
        </head>
        <body>
        <div id="player"></div>
        <script>
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/iframe_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

        var player;
        function onYouTubeIframeAPIReady() {
            player = new YT.Player('player', {
                videoId: '\(videoId ?? "")',
                events: {
                    'onReady': onPlayerReady
                },
                playerVars: {
                    'playsinline': 1,
                    'autoplay': 1,
                },
            });
        }

        function onPlayerReady(event) {
            event.target.playVideo();
        }

        function seekTo(seconds) {
            if(player && player.seekTo) {
                player.seekTo(seconds, true);
            }
        }
        
        function onPlayerStateChange(event) {
            switch(event.data) {
                case YT.PlayerState.UNSTARTED:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('unstarted');
                    break;
                case YT.PlayerState.ENDED:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('ended');
                    break;
                case YT.PlayerState.PLAYING:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('playing');
                    break;
                case YT.PlayerState.PAUSED:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('paused');
                    break;
                case YT.PlayerState.BUFFERING:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('buffering');
                    break;
            }
        }
        </script>
        </body>
        </html>
        """
    }
    
    private func updatePreviousValues(context: Context) {
        context.coordinator.previousAutoplay = autoplay
        context.coordinator.previousPlaysinline = autoplay
        context.coordinator.previousVideoLink = videoLink
    }
    
    private func extractVideoId(from url: String) -> String? {
        let patterns = [
            "(?<=watch\\?v=)[^#&?\\n]*",            // Standard URL
            "(?<=youtu.be/)[^#&?\\n]*",             // Shortened URL
            "(?<=youtube.com/embed/)[^#&?\\n]*",    // Embed URL
            "(?<=youtube.com/shorts/)[^#&?\\n]*"    // Shorts URL
        ]
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: url.utf16.count)
            if let match = regex?.firstMatch(in: url, options: [], range: range) {
                if let range = Range(match.range, in: url) {
                    return String(url[range])
                }
            }
        }
        return nil
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: YouTubeWebView
        weak var webView: WKWebView?
        
        var previousAutoplay: Int?
        var previousPlaysinline: Int?
        var previousVideoLink: String?
        var previousState: PlayerState?
        
        init(_ parent: YouTubeWebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let messageBody = message.body as? String else { return }
            let state = PlayerState(rawValue: messageBody) ?? .unstarted
            parent.state = state
            parent.onStateChange?(state)
        }
    }
}
