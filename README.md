# SpotifyApp

A quick SwiftUI app using the Spotify SDK to display the currently player title/artist/album and album artwork.

Be sure to add your Spotify Client ID and Redirect URL to the SpotifyCredentials.swift file.

The tutorial @ https://developer.spotify.com/documentation/ios/quick-start/ uses either an AppDelegate or UIScene.  This app uses .onOpenURL and .onChange of the ContentView to accomplish the same thing.

Be sure to get the most current version of the Spotify framework!

The 'bluetooth-peripheral' branch creates a BLE peripheral that has the track attributes as characteristics.  It's mostly unfinished.
