//
//  SpotifyManager.swift
//  metaspot
//
//  Created by Tom on 7/12/21.
//

import SwiftUI
import UIKit.UIImage

class SpotifyManager: NSObject, ObservableObject {
        
    static let SpotifyClientID = "2c4a5f2650cf4efe8a08c8c435f437ec"
    static let SpotifyRedirectURL = URL(string: "spotify-peripheral-app://spotify-login-callback")!
    
    @Published var playerState:SPTAppRemotePlayerState?
    
    private let timerInterval:Double = 0.1
    private var timer:Timer!

    @Published var statusMessage:String = ""
    @Published var peripheralState:String = ""
    
    @Published var trackInfo:SpotifyTrackInfo = SpotifyTrackInfo(title: "", artist: "", album: "")
    @Published var trackAlbumArt:SpotifyAlbumArt = SpotifyAlbumArt()
    
    var accessToken = ""
        
    lazy var configuration = SPTConfiguration(
        clientID: SpotifyManager.SpotifyClientID,
        redirectURL: SpotifyManager.SpotifyRedirectURL
    )
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()

    public override init() {
        super.init()
        
        trackInfo.position = 0
        
        self.timer = Timer(timeInterval: timerInterval, repeats: true, block: { [self] timer in
            if let playerState = self.playerState {
                if !playerState.isPaused {
                    self.trackInfo.position = self.trackInfo.position + Int(self.timerInterval * 1000) // timer fires with resolution in seconds, position is milliseconds
                }
                self.trackInfo.position = min(self.trackInfo.position, Int(playerState.track.duration))
            }
        })
        RunLoop.current.add(timer, forMode: .common)
    }
    
    var sendingEOM = false
    var sendDataIndex: Int = 0
    let NOTIFY_MTU = 20
    
    var lastSendDataIndex:Int = 0
}

extension SpotifyManager: SPTAppRemoteDelegate {
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("appRemote connected")
        
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
                self.appRemote.connect() // try again?
            }
        })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("appRemote failed")
        print(error.debugDescription)
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("appRemote disconnected")
    }
}

extension SpotifyManager: SPTAppRemotePlayerStateDelegate {
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        self.playerState = playerState
        
        print("player state changed")
        print("isPaused", playerState.isPaused)
        print("track.uri", playerState.track.uri)
        print("track.name", playerState.track.name)
        print("track.imageIdentifier", playerState.track.imageIdentifier)
        print("track.artist.name", playerState.track.artist.name)
        print("track.album.name", playerState.track.album.name)
        print("track.isSaved", playerState.track.isSaved)
        print("playbackSpeed", playerState.playbackSpeed)
        print("playbackOptions.isShuffling", playerState.playbackOptions.isShuffling)
        print("playbackOptions.repeatMode", playerState.playbackOptions.repeatMode.hashValue)
        print("playbackPosition", playerState.playbackPosition)
                
        self.trackInfo = SpotifyTrackInfo(
            title: playerState.track.name,
            artist: playerState.track.artist.name,
            album: playerState.track.album.name,
            position: Int(playerState.playbackPosition),
            duration: Int(playerState.track.duration)
        )

        self.trackAlbumArt.imageData = Data()
        fetchArtwork(for: playerState.track)
    }
    
    func fetchArtwork(for track: SPTAppRemoteTrack) {
        appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize.zero, callback: { [weak self] (image, error) in
            if let error = error {
                print("Error fetching track image: " + error.localizedDescription)
            } else if let image = image as? UIImage{
                
                self!.trackAlbumArt.imageData = image.pngData()
                
            }
        })
    }
}

//extension SpotifyManager: SPTSessionManagerDelegate {
//    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
//        print("sessionManager didInitiate")
//        self.appRemote.connectionParameters.accessToken = session.accessToken
//        self.appRemote.connect()
//    }
//
//    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
//        print(error)
//    }
//}


