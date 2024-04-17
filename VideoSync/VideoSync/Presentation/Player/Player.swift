//
//  Player.swift
//  VideoSync
//
//  Created by ton252 on 17.04.2024.
//

import Foundation
import Combine

enum PlayerState: String, Codable {
    case unstarted
    case ended
    case playing
    case paused
    case buffering
}

struct PlayerVars: Equatable {
    var autoplay: Int = 1
    var playsinline: Int = 1
}

protocol PlayerDelegate: AnyObject {
    func loadLink(player: Player, link: String?)
    func updateParams(player: Player, params: PlayerVars)
    
    func getState(player: Player) -> PlayerState
    func getCurrentTime(player: Player) -> TimeInterval
    
    func play(player: Player)
    func pause(player: Player)
    func seek(player: Player, to time: TimeInterval)
}

class Player: ObservableObject {
    var link: String? {
        didSet { delegate?.loadLink(player: self, link: link) }
    }
    
    var parameters: PlayerVars {
        didSet { delegate?.updateParams(player: self, params: parameters) }
    }
    
    var state: PlayerState {
        return delegate.getState(player: self)
    }
    
    var currentTime: TimeInterval {
        return delegate.getCurrentTime(player: self)
    }
    
    let onTimeChange = PassthroughSubject<TimeInterval, Never>()
    let onStateChange = PassthroughSubject<PlayerState, Never>()
    
    weak var delegate: PlayerDelegate!
    
    init(
        link: String? = nil,
        parameters: PlayerVars? = nil
    ) {
        self.link = link
        self.parameters = parameters ?? PlayerVars()
    }
    
    func play() {
        delegate.play(player: self)
    }
    
    func pause() {
        delegate.pause(player: self)
    }
    
    func seek(to time: TimeInterval) {
        delegate.seek(player: self, to: time)
    }
}


