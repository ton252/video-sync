//
//  YouTubePlayerWebView.swift
//  VideoSync
//
//  Created by ton252 on 17.04.2024.
//

import SwiftUI
import WebKit

protocol YouTubePlayerWebViewDelegate: AnyObject {
    func youTubePlayerStateChange(_ player: YouTubePlayerWebView, state: PlayerState)
    func youTubePlayerTimeChange(_ player: YouTubePlayerWebView, time: TimeInterval)
}

class YouTubePlayerWebView: UIView {
    private(set) var state: PlayerState = .unstarted
    private(set) var currentTime: TimeInterval = 0
    private(set) var bufferingTime: TimeInterval = 0
    
    weak var delegate: YouTubePlayerWebViewDelegate?
    
    private var webView: WKWebView!
    private var foregroundView: UIView!
    private let scriptHandlerName = "youtubePlayerUpdate"
    
    var videoID: String? {
        didSet { loadHTMLString() }
    }
    
    var parameters: PlayerVars = PlayerVars() {
        didSet { loadHTMLString() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        createWebView()
        createForegroundView()
        configureLayout()
    }
    
    private func createWebView() {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: scriptHandlerName)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: configuration)
    }
    
    private func createForegroundView() {
        foregroundView = UIView()
        foregroundView.backgroundColor = .black
    }
    
    private func configureLayout() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        foregroundView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(webView)
        addSubview(foregroundView)
        
        var constraints = [NSLayoutConstraint]()
        constraints.append(webView.topAnchor.constraint(equalTo: topAnchor))
        constraints.append(webView.bottomAnchor.constraint(equalTo: bottomAnchor))
        constraints.append(webView.leadingAnchor.constraint(equalTo: leadingAnchor))
        constraints.append(webView.trailingAnchor.constraint(equalTo: trailingAnchor))
        
        constraints.append(foregroundView.topAnchor.constraint(equalTo: topAnchor))
        constraints.append(foregroundView.bottomAnchor.constraint(equalTo: bottomAnchor))
        constraints.append(foregroundView.leadingAnchor.constraint(equalTo: leadingAnchor))
        constraints.append(foregroundView.trailingAnchor.constraint(equalTo: trailingAnchor))
        
        NSLayoutConstraint.activate(constraints)
    }
}

extension YouTubePlayerWebView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            let messageBody = message.body as? String,
            let json = dictFromJSONString(messageBody),
            let type = json["type"] as? String,
            let state = json["state"] as? Int,
            let currentTime = json["currentTime"] as? TimeInterval,
            let bufferingTime = json["bufferingTime"] as? TimeInterval
        else { return }
        
        self.state = PlayerState.fromYouTubeState(state)
        self.currentTime = currentTime
        self.bufferingTime = bufferingTime
                
        switch type {
        case "player_ready":
            foregroundView.isHidden = true
        case "player_state":
            delegate?.youTubePlayerStateChange(self, state: self.state)
        case "player_time_update":
            delegate?.youTubePlayerTimeChange(self, time: self.currentTime)
        default:
            break
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
    
    func fetchCurrentTime(completion: @escaping (TimeInterval) -> ()) {
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

extension YouTubePlayerWebView {
    
    fileprivate func loadHTMLString() {
        foregroundView.isHidden = false
        webView.loadHTMLString(htmlString, baseURL: nil)
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
                    videoId: '\(videoID ?? "")',
                    events: {
                        'onReady': onPlayerReady,
                        'onStateChange': onPlayerStateChange
                    },
                    playerVars: {
                        'playsinline': \(parameters.playsinline),
                        'autoplay': \(parameters.autoplay),
                    },
                });
            }
            
            function onPlayerReady(event) {
                sendUpdate({ type: "player_ready" });
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
            
            function getPlayerState() {
                if(player && player.getPlayerState) {
                    return player.getPlayerState();
                }
                return YT.PlayerState.UNSTARTED;
            }
            
            function getCurrentTime() {
                if(player && player.getCurrentTime) {
                    return player.getCurrentTime();
                }
                return 0;
            }
            
            function getDuration() {
                if(player && player.getDuration) {
                    return player.getDuration();
                }
                return 0;
            }
            
            function getBufferingTime() {
                if(player && player.getDuration && player.getVideoLoadedFraction) {
                    return player.getDuration() * player.getVideoLoadedFraction();
                }
                return 0;
            }
            
            function startScheduler() {
                if (!currentTimeInterval) {
                    currentTimeInterval = setInterval(function() {
                        sendUpdate({ type: "player_time_update" });
                    }, 1000);
                }
            }
            
            function stopScheduler() {
                if (currentTimeInterval) {
                    clearInterval(currentTimeInterval);
                    currentTimeInterval = null;
                        sendUpdate({ type: "player_time_update" });
                }
            }
            
            function onPlayerStateChange(event) {
                switch(event.data) {
                    case YT.PlayerState.UNSTARTED:
                        sendUpdate({ type: "player_state" })
                        break;
                    case YT.PlayerState.PLAYING:
                        sendUpdate({ type: "player_state" })
                        startScheduler();
                        break;
                    case YT.PlayerState.ENDED:
                        stopScheduler();
                        sendUpdate({ type: "player_state" })
                        break;
                    case YT.PlayerState.PAUSED:
                        stopScheduler();
                        sendUpdate({ type: "player_state" })
                        break;
                    case YT.PlayerState.BUFFERING:
                        sendUpdate({ type: "player_state" })
                        break;
                }
            }
            
            function sendUpdate(json) {
                json.state = json.state || getPlayerState();
                json.currentTime = json.currentTime || getCurrentTime();
                json.bufferingTime = json.bufferingTime || getBufferingTime();
                sendJSON(json);
            }
            
            function sendJSON(json) {
               window.webkit.messageHandlers.youtubePlayerUpdate.postMessage(JSON.stringify(json));
            }
            </script>
            </body>
            </html>
            """
    }
}

fileprivate extension PlayerState {
    static func fromYouTubeState(_ state: Int) -> PlayerState {
        switch state {
        case -1:
            return .unstarted
        case 0:
            return .ended
        case 1:
            return .playing
        case 2:
            return .paused
        case 3:
            return .buffering
        default:
            return .unstarted
        }
    }
}

