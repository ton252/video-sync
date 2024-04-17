//
//  YouTubePlayer.swift
//  VideoSync
//
//  Created by ton252 on 17.04.2024.
//

import SwiftUI

struct YouTubePlayer: UIViewRepresentable {
    @ObservedObject var player: Player
    
    init(player: Player) {
        self.player = player
    }
    
    func makeUIView(context: Context) -> YouTubePlayerWebView {
        let playerView = YouTubePlayerWebView()
        playerView.videoID = player.link
        playerView.parameters = player.parameters
        
        let coordinator = context.coordinator
        coordinator.playerView = playerView
        coordinator.previousVideoID = player.link
        coordinator.previousParameters = player.parameters
        
        return playerView
    }
    
    func updateUIView(_ uiView: YouTubePlayerWebView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.previousVideoID != player.link {
            uiView.videoID = player.link
            coordinator.previousVideoID = player.link
        }
        if coordinator.previousParameters != player.parameters {
            uiView.parameters = player.parameters
            coordinator.previousParameters = player.parameters
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        player.delegate = coordinator
        return coordinator
    }
    
    class Coordinator: NSObject, PlayerDelegate, YouTubePlayerWebViewDelegate {
        var parent: YouTubePlayer
        
        weak var playerView: YouTubePlayerWebView? {
            didSet { playerView?.delegate = self }
        }

        var previousVideoID: String?
        var previousParameters: PlayerVars?
        
        init(_ parent: YouTubePlayer) {
            self.parent = parent
            super.init()
        }
        
        func loadLink(player: Player, link: String?) {
            playerView?.videoID = link
        }
        
        func updateParams(player: Player, params: PlayerVars) {
            playerView?.parameters = params
        }
        
        func getState(player: Player) -> PlayerState {
            return playerView!.state
        }
        
        func getCurrentTime(player: Player) -> TimeInterval {
            return playerView!.currentTime
        }
        
        func play(player: Player) {
            playerView?.play()
        }
        
        func pause(player: Player) {
            playerView?.pause()
        }
        
        func seek(player: Player, to time: TimeInterval) {
            playerView?.seek(time: time)
        }
        
        func youTubePlayerStateChange(_ player: YouTubePlayerWebView, state: PlayerState) {
            parent.player.onStateChange.send(state)
        }
        
        func youTubePlayerTimeChange(_ player: YouTubePlayerWebView, time: TimeInterval) {
            parent.player.onTimeChange.send(time)
        }
    }
}
