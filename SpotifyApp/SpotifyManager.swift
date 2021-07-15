//
//  SpotifyManager.swift
//  metaspot
//
//  Created by Tom on 7/12/21.
//

import SwiftUI
import UIKit.UIImage
import CoreBluetooth

class SpotifyManager: NSObject, ObservableObject {
    
    public static let serviceUUID = CBUUID.init(string: "b4250400-fb4b-4746-b2b0-93f0e61122c5")

    let trackInfoCharacteristic = CBMutableCharacteristic(type: SpotifyTrackInfo.characteristicUUID, properties: [.notify,  .read, .writeWithoutResponse], value: nil, permissions: [.readable])
    let artCharacteristic = CBMutableCharacteristic(type: SpotifyAlbumArt.characteristicUUID, properties: [.notify,  .read, .writeWithoutResponse], value: nil, permissions: [.readable])
    
    static let SpotifyClientID = "2c4a5f2650cf4efe8a08c8c435f437ec"
    static let SpotifyRedirectURL = URL(string: "spotify-peripheral-app://spotify-login-callback")!
    
    @Published var playerState:SPTAppRemotePlayerState?
    
    private let timerInterval:Double = 0.1
    private var timer:Timer!
    private var peripheralManager:CBPeripheralManager!

    @Published var statusMessage:String = ""
    @Published var peripheralState:String = ""
    
    @Published var trackInfo:SpotifyTrackInfo = SpotifyTrackInfo(title: "", artist: "", album: "")
    @Published var trackAlbumArt:SpotifyAlbumArt = SpotifyAlbumArt()
    
    var accessToken = ""
    
    private var infoSubscribers = [CBCentral]()
    private var artSubscribers = [CBCentral]()
    
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
                    
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    var sendingEOM = false
    var sendDataIndex: Int = 0
    let NOTIFY_MTU = 20
    
    var lastSendDataIndex:Int = 0
}

extension SpotifyManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        
        case .unknown:
            peripheralState = "device is unknown"
        case .resetting:
            peripheralState = "device is resetting"
        case .unsupported:
            peripheralState = "device is unsupported"
        case .unauthorized:
            peripheralState = "device is unauthorized"
        case .poweredOff:
            peripheralState = "device is powerd off"
        case .poweredOn:
            peripheralState = "device is powered on"
            addServices()
        @unknown default:
            print("BT device in unknown state")
            peripheralState = "device is unknown"
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        statusMessage = "Data was read"
        
        if let _ = self.playerState {
            switch request.characteristic.uuid {
                
            case SpotifyTrackInfo.characteristicUUID:
                    
                request.value = trackInfo.data
                peripheral.respond(to: request, withResult: .success)
             
//            case SpotifyAlbumArt.characteristicUUID:
//                print("recd read request for album artwork")
//                request.value = Data()
//                peripheral.respond(to:request, withResult: .success)
                
            default:
                print("unknown char uuid")
                peripheral.respond(to: request, withResult: .attributeNotFound)
            }
        }
    }
    
    func addServices() {

        let service = CBMutableService(type: SpotifyManager.serviceUUID, primary: true)
        service.characteristics = [trackInfoCharacteristic, artCharacteristic]
        //service.characteristics = [trackInfoCharacteristic]
        peripheralManager.add(service)
        startAdvertising()
    }
    
    private func startAdvertising() {
        statusMessage = "Advertising Data"
        
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey: "BLEPeripheralApp", CBAdvertisementDataServiceUUIDsKey: [SpotifyManager.serviceUUID] ])
    }

    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        if characteristic == trackInfoCharacteristic {
            infoSubscribers.append(central)
        } else if characteristic == artCharacteristic {
            artSubscribers.append(central)
            
//            if let _ = trackAlbumArt.imageData {
//                self.sendDataIndex = 0
//                DispatchQueue.global(qos: .background).async {
//                    print("(did subscribeTo) publishing Artwork \(self.trackAlbumArt.imageData!.count)")
//                    self.publishArtWork()
//                }
//            }
        }
        
    }
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

        peripheralManager.updateValue(self.trackInfo.data!, for: trackInfoCharacteristic, onSubscribedCentrals: infoSubscribers)

        self.trackAlbumArt.imageData = Data()
        fetchArtwork(for: playerState.track)
    }
    
    func fetchArtwork(for track: SPTAppRemoteTrack) {
        appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize.zero, callback: { [weak self] (image, error) in
            if let error = error {
                print("Error fetching track image: " + error.localizedDescription)
            } else if let image = image as? UIImage{
                
                self!.trackAlbumArt.imageData = image.pngData()
                
                if self!.artSubscribers.count > 0 {
                    self!.sendDataIndex = 0
                    DispatchQueue.global(qos: .background).async {
                        print("sending new art work to subscribers! ")
                        print("(fetchartwork) publishing Artwork \(self!.trackAlbumArt.imageData!.count)")

                        self!.publishArtWork()
                    }
                }
            }
        })
    }
    
    func publishArtWork() {

        if sendingEOM {
            // send it
            let didSend = peripheralManager?.updateValue(
                "EOM".data(using: String.Encoding.utf8)!,
                for: artCharacteristic,
                onSubscribedCentrals: nil
            )
            
            // Did it send?
            if (didSend == true) {
                
                // It did, so mark it as sent
                sendingEOM = false
                
                print("\n\nSent art work EOM")
            }
            
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // We're not sending an EOM, so we're sending data
        
        // Is there any left to send?
        guard sendDataIndex < self.trackAlbumArt.imageData!.count else {
            // No data left.  Do nothing
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        var didSend = true
        
        while didSend {
            // Make the next chunk
            
            // Work out how big it should be
            var amountToSend = self.trackAlbumArt.imageData!.count - sendDataIndex
            
            // Can't be longer than 20 bytes
            if (amountToSend > NOTIFY_MTU) {
                amountToSend = NOTIFY_MTU;
            }
            
            // Copy out the data we want
            let chunk = self.trackAlbumArt.imageData!.withUnsafeBytes{(body: UnsafePointer<UInt8>) in
                return Data(
                    bytes: body + sendDataIndex,
                    count: amountToSend
                )
            }
            
            // Send it
            didSend = peripheralManager!.updateValue(
                chunk as Data,
                for: artCharacteristic,
                onSubscribedCentrals: nil
            )
            
            // If it didn't work, drop out and wait for the callback
            if (!didSend) {
                return
            }
            
            //print("Sent: \(String(decoding: chunk, as: UTF8.self))")
            
            if lastSendDataIndex > sendDataIndex {
                print("wtf??")
            }
            
            // It did send, so update our index
            sendDataIndex += amountToSend;
            
            lastSendDataIndex = sendDataIndex
            
            //print("sent: \(sendDataIndex)/\(self.trackAlbumArt.imageData!.count)")
            
            // Was it the last one?
            if (sendDataIndex >= self.trackAlbumArt.imageData!.count) {
                
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                sendingEOM = true
                
                // Send it
                let eomSent = peripheralManager!.updateValue(
                    "EOM".data(using: String.Encoding.utf8)!,
                    for: artCharacteristic,
                    onSubscribedCentrals: nil
                )
                
                if (eomSent) {
                    // It sent, we're all done
                    sendingEOM = false
                    print("\n\nSent: EOM")
                }
                
                return
            }
        }
    }
    
    /** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        publishArtWork()
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


