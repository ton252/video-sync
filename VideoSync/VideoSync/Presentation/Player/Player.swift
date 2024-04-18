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
    func getBufferingTime(player: Player) -> TimeInterval
    
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
    
    private(set) var state: PlayerState = .unstarted
    private(set) var currentTime: TimeInterval = 0
    private(set) var bufferingTime: TimeInterval = 0
    
    let onTimeChange = PassthroughSubject<TimeInterval, Never>()
    let onStateChange = PassthroughSubject<PlayerState, Never>()
    
    weak var delegate: PlayerDelegate?
    
    init(
        link: String? = nil,
        parameters: PlayerVars? = nil
    ) {
        print("Init player")
        self.link = link
        self.parameters = parameters ?? PlayerVars()
    }
    
    deinit {
        print("Deinit player")
    }
    
    func play() {
        delegate?.play(player: self)
    }
    
    func pause() {
        delegate?.pause(player: self)
    }
    
    func seek(to time: TimeInterval) {
        delegate?.seek(player: self, to: time)
    }
    
    func update() {
        guard let delegate = delegate else { return }
        state = delegate.getState(player: self)
        currentTime = delegate.getCurrentTime(player: self)
        bufferingTime = delegate.getBufferingTime(player: self)
        print(delegate.getBufferingTime(player: self))
    }
}


