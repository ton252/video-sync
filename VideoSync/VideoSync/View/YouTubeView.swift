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
    @Binding var allowContols: Bool
    let controller: YouTubeWebViewController
    
    @State private var currentTime: TimeInterval = 0.0
    
    var body: some View {
        ZStack {
            Color.black
            if videoLink != nil {
                YouTubeWebView(
                    videoLink:  Binding<String>(
                        get: { videoLink ?? "" },
                        set: { videoLink = $0 }
                    ),
                    controller: controller,
                    backgroundColor: .black
                )
            }
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(allowContols)
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

class YouTubeWebViewController: ObservableObject {
    fileprivate weak var coordinator: YouTubeWebView.Coordinator?
    
    var currentTime: TimeInterval {
        return 0
    }
    
    var state: PlayerState {
        return .unstarted
    }
    
    func play() {
        coordinator?.play()
    }
    
    func pause()  {
        coordinator?.pause()
    }
    
    func restart() {
        coordinator?.restart()
    }
    
    func seek(time: TimeInterval) {
        coordinator?.seek(time: time)
    }
}

struct YouTubeWebView: UIViewRepresentable {
    @Binding var videoLink: String
    
    let autoplay: Int
    let playsinline: Int
    let backgroundColor: Color?
    
    @State var updatingTrigger: Bool = false
    
    private let controller: YouTubeWebViewController
    private let extractor = YouTubeExtractor()
    
    private var videoId: String? {
        return extractor.extractVideoId(link: videoLink)
    }
    
    init(
        videoLink: Binding<String>,
        autoplay: Int = 1,
        playsinline: Int = 1,
        controller: YouTubeWebViewController = YouTubeWebViewController(),
        backgroundColor: Color?
    ) {
        self._videoLink = videoLink
        self.backgroundColor = backgroundColor
        
        self.autoplay = autoplay
        self.playsinline = playsinline
        self.controller = controller
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: webViewConfig(context: context))
        let backgroundView = UIView()

        webView.addSubview(backgroundView)
        backgroundView.frame = webView.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        context.coordinator.webView = webView
        context.coordinator.backroundView = backgroundView
        
        updatePreviousValues(context: context)
        updateBackgroundView(context: context)

        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.previousVideoLink != videoLink {
            uiView.loadHTMLString(htmlString, baseURL: nil)
        }
        
        updateBackgroundView(context: context)
        updatePreviousValues(context: context)
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        controller.coordinator = coordinator
        return coordinator
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
    
    private func updateBackgroundView(context: Context) {
        let coordinator = context.coordinator
        coordinator.backroundView?.backgroundColor = backgroundColor != nil ? UIColor(backgroundColor!) : nil
        coordinator.backroundView?.isHidden = backgroundColor == nil || coordinator.isBackgroundViewHidden
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
                    background-color: #000000;
                    color: white;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                }
                #player {
                    width: 100%;
                    height: 100vh;
                    background-color: #000000;
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
            window.webkit.messageHandlers.youtubePlayerUpdate.postMessage('PlayerReady: ready');
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
        
        function restartVideo() {
            if(player && player.seekTo && player.playVideo) {
                player.seekTo(0, true);
                player.playVideo();
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
        context.coordinator.previousVideoLink = videoLink
    }
    
    private func extractVideoId(from url: String) -> String? {
        let urlString = URLComponents(string: url).flatMap { urlComp in
            var comp = urlComp
            comp.queryItems = nil
            return comp.string
        } ?? ""
        let patterns = [
            "(?<=watch\\?v=)[^#&?\\n]*",            // Standard URL
            "(?<=youtu.be/)[^#&?\\n]*",             // Shortened URL
            "(?<=youtube.com/embed/)[^#&?\\n]*",    // Embed URL
            "(?<=youtube.com/shorts/)[^#&?\\n]*"    // Shorts URL
        ]
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: urlString.utf16.count)
            if let match = regex?.firstMatch(in: urlString, options: [], range: range) {
                if let range = Range(match.range, in: urlString) {
                    return String(urlString[range])
                }
            }
        }
        return nil
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: YouTubeWebView
        weak var webView: WKWebView?
        weak var backroundView: UIView?
        var previousVideoLink: String?
        
        var isBackgroundViewHidden: Bool = false
        var state: PlayerState = .unstarted
        var currentTime: TimeInterval = 0
        
        init(_ parent: YouTubeWebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let messageBody = message.body as? String else { return }
            
            if messageBody.contains("PlayerReady: ") {
                isBackgroundViewHidden = true
                parent.updatingTrigger.toggle()
            } else if messageBody.contains("PlayerState: ") {
                let data = messageBody.replacingOccurrences(of: "PlayerState: ", with: "")
                let state = PlayerState(rawValue: data) ?? .unstarted
                self.state = state
                // parent.onStateChange?(state)
            } else if messageBody.contains("CurrentTime: ") {
                let data = messageBody.replacingOccurrences(of: "CurrentTime: ", with: "")
                let time = TimeInterval(data) ?? 0
                currentTime = time
                // parent.onTimeChange?(time)
            }
        }
        
        func play() {
            webView?.evaluateJavaScript("playVideo();")
        }
        
        func pause() {
            webView?.evaluateJavaScript("pauseVideo();")
        }
        
        func seek(time: TimeInterval) {
            webView?.evaluateJavaScript("seekTo(\(time));")
        }
        
        func restart() {
            webView?.evaluateJavaScript("restartVideo();")
        }
        
        private func fetchCurrentTime(completion: @escaping (TimeInterval) -> ()) {
            webView?.evaluateJavaScript("getCurrentTime();") { (result, error) in
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
    }
}


class YouTubeExtractor {
    func extractVideoId(link: String) -> String? {
        let urlString = URLComponents(string: link).flatMap { urlComp in
            var comp = urlComp
            comp.queryItems = nil
            return comp.string
        } ?? ""
        let patterns = [
            "(?<=watch\\?v=)[^#&?\\n]*",            // Standard URL
            "(?<=youtu.be/)[^#&?\\n]*",             // Shortened URL
            "(?<=youtube.com/embed/)[^#&?\\n]*",    // Embed URL
            "(?<=youtube.com/shorts/)[^#&?\\n]*"    // Shorts URL
        ]
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: urlString.utf16.count)
            if let match = regex?.firstMatch(in: urlString, options: [], range: range) {
                if let range = Range(match.range, in: urlString) {
                    return String(urlString[range])
                }
            }
        }
        return nil
    }
    
    func isValidLink(_ link: String) -> Bool {
        return extractVideoId(link: link) != nil
    }
}

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
