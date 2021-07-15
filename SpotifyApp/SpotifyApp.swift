//
//  metaspotApp.swift
//  metaspot
//
//  Created by Tom on 7/9/21.
//

import SwiftUI

@main
struct SpotifyApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    
    var spotify = SpotifyManager()
        
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL(perform: { url in
                    let parameters = spotify.appRemote.authorizationParameters(from: url);
                    
                    if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
                        spotify.appRemote.connectionParameters.accessToken = access_token
                        spotify.accessToken = access_token
                        spotify.appRemote.connect()
                    } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
                        print(errorDescription)
                    }
                })
                .onChange(of: scenePhase) { newScenePhase in
                    switch newScenePhase {
                    case .active:
                        print("App is active")
                        if let _ = spotify.appRemote.connectionParameters.accessToken {
                            spotify.appRemote.connect()
                        }
                    case .inactive:
                        print("App is inactive")
                        if spotify.appRemote.isConnected {
                            spotify.appRemote.disconnect()
                        }
                    case .background:
                        print("App is in background")
                    @unknown default:
                        print("Oh - interesting: I received an unexpected new value.")
                    }
                }
                .environmentObject(spotify)
        }
    }
}



