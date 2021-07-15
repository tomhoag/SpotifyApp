//
//  ContentView.swift
//  metaspot
//
//  Created by Tom on 7/9/21.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var spotify:SpotifyManager
    
    var body: some View {
        VStack(alignment:.center) {
            
            Text("Spotify Proxy App")
                .font(.title)
            Text( spotify.trackInfo.title )
                .font(.largeTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(spotify.trackInfo.artist)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(spotify.trackInfo.album )
                .font(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            spotify.trackAlbumArt.image // returns and Image
            
            HStack(alignment:.top) {
                Text("\(Double(spotify.trackInfo.position).minuteSecond)")
                    .font(.footnote)
                Spacer()
                Text( (spotify.playerState != nil) ? Double(spotify.playerState!.track.duration).minuteSecond : "")
                    .font(.footnote)
            }
            .padding(.bottom, 0)

            ProgressView(
                "",
                value: Double(spotify.trackInfo.position),
                total: (spotify.playerState != nil) ? Double(spotify.trackInfo.duration) : Double(spotify.trackInfo.position)
            )
            .padding(.top, -10)
            
            .font(Font.system((.largeTitle)))
            Spacer()
            
//            VStack {
//                if let playerState = spotify.playerState {
//                    Text("track.uri \(playerState.track.uri)")
//                    Text("track.isSaved \(playerState.track.isSaved ? "true" : "false" )")
//                    Text("playbackSpeed \(playerState.playbackSpeed)")
//                    Text("playbackOptions.isShuffling \(playerState.playbackOptions.isShuffling ? "true" : "false")")
//                    Text("playbackOptions.repeatMode \(playerState.playbackOptions.repeatMode.hashValue)")
//                    Text("playbackPosition \(playerState.playbackPosition)")
//                }
//            }
        }
        .padding()
        .onAppear() {
            connect()
        }
    }
    
    func connect() {
        spotify.appRemote.authorizeAndPlayURI("")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


