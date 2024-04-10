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
    @State var isPlaying: Bool = true
    @State var currentTime: TimeInterval = 0.0
    
    var body: some View {
        ZStack {
            Color.black
            if let videoLink = videoLink {
                YouTubeWebView(videoLink: Binding.constant(videoLink), isPlaying: $isPlaying, currentTime: $currentTime, onStateChange: {
                    state in
                    print(state)
                })
            }
        }
        .frame(maxWidth: .infinity)
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

struct YouTubeWebView: UIViewRepresentable {
    @Binding var videoLink: String
    @Binding var autoplay: Int
    @Binding var playsinline: Int
    @Binding var isPlaying: Bool
    @Binding var currentTime: TimeInterval
        
    var onStateChange: ((PlayerState) -> ())?
        
    var videoId: String? {
        return extractVideoId(from: videoLink)
    }
        
    init(
        videoLink: Binding<String>,
        autoplay: Binding<Int> = .constant(1),
        playsinline: Binding<Int> = .constant(1),
        isPlaying: Binding<Bool> = .constant(false),
        currentTime: Binding<TimeInterval> = .constant(0),
        onStateChange: ((PlayerState) -> ())? = nil
    ) {
        self._videoLink = videoLink
        self._autoplay = autoplay
        self._playsinline = playsinline
        self._isPlaying = isPlaying
        self._currentTime = currentTime
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
        let coordinator = context.coordinator
        if coordinator.previousAutoplay != autoplay ||
            coordinator.previousPlaysinline != playsinline ||
            coordinator.previousVideoLink != videoLink
        {
            uiView.loadHTMLString(htmlString, baseURL: nil)
        }
                
        if currentTime != coordinator.previousCurrentTime {
            seek(uiView, time: currentTime)
        }
                
        if coordinator.state == .playing && isPlaying == false {
            pause(uiView)
        } else if coordinator.state == .paused && isPlaying == true {
            play(uiView)
        }
                
        updatePreviousValues(context: context)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func play(_ uiView: WKWebView) {
        uiView.evaluateJavaScript("playVideo();")
    }
    
    private func pause(_ uiView: WKWebView) {
        uiView.evaluateJavaScript("pauseVideo();")
    }
    
    private func seek(_ uiView: WKWebView, time: TimeInterval) {
        uiView.evaluateJavaScript("seekTo(\(time));")
    }
    
    private func fetchCurrentTime(_ uiView: WKWebView, completion: @escaping (TimeInterval) -> ()) {
        uiView.evaluateJavaScript("getCurrentTime();") { (result, error) in
            if error != nil {
                completion(0)
                return
            }
            if let currentTime = result as? TimeInterval {
                completion(currentTime)
            } else {
                completion(0)
            }
        }
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
        var currentTimeInterval;

        function onYouTubeIframeAPIReady() {
            player = new YT.Player('player', {
                videoId: '\(videoId ?? "")',
                events: {
                    'onReady': onPlayerReady,
                    'onStateChange': onPlayerStateChange
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
        
        function playVideo() {
            if(player && player.playVideo) {
                player.playVideo();
            }
        }
        
        function pauseVideo() {
            if(player && player.pauseVideo) {
                player.pauseVideo();
            }
        }
        
        function getCurrentTime() {
            if(player && player.getCurrentTime) {
                return player.getCurrentTime();
            }
            return 0;
        }
        
        function startScheduler() {
            if (!currentTimeInterval) {
                currentTimeInterval = setInterval(function() {
                    var currentTime = getCurrentTime();
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('CurrentTime: ' + currentTime);
                }, 1000);
            }
        }
        
        function stopScheduler() {
            if (currentTimeInterval) {
                clearInterval(currentTimeInterval);
                currentTimeInterval = null;
                var currentTime = getCurrentTime();
                window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('CurrentTime: ' + currentTime);
            }
        }
        
        function onPlayerStateChange(event) {
            switch(event.data) {
                case YT.PlayerState.UNSTARTED:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('PlayerState: unstarted');
                    break;
                case YT.PlayerState.PLAYING:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('PlayerState: playing');
                    startScheduler();
                    break;
                case YT.PlayerState.ENDED:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('PlayerState: ended');
                    stopScheduler();
                    break;
                case YT.PlayerState.PAUSED:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('PlayerState: paused');
                    stopScheduler();
                    break;
                case YT.PlayerState.BUFFERING:
                    window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('PlayerState: buffering');
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
        context.coordinator.previousCurrentTime = currentTime
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
        
        var state: PlayerState?
        
        var previousAutoplay: Int?
        var previousPlaysinline: Int?
        var previousVideoLink: String?
        var previousIsPlaying: Bool?
        var previousCurrentTime: TimeInterval?
        
        init(_ parent: YouTubeWebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let messageBody = message.body as? String else { return }
            
            if messageBody.contains("PlayerState: ") {
                let data = messageBody.replacingOccurrences(of: "PlayerState: ", with: "")
                let state = PlayerState(rawValue: data) ?? .unstarted
                self.state = state
                parent.onStateChange?(state)
            } else if messageBody.contains("CurrentTime: ") {
                let data = messageBody.replacingOccurrences(of: "CurrentTime: ", with: "")
                let time = TimeInterval(data) ?? 0
                print(time)
                //self.parent.currentTime = time
            }
        }
    }
}
