//
//  SpotifyTrackInfo.swift
//  SpotifyApp
//
//  Created by Tom on 7/13/21.
//

import Foundation
import CoreBluetooth
import SwiftUI

struct SpotifyAlbumArt:Codable {
    public static let characteristicUUID = CBUUID.init(string: "c4250402-fb4b-4746-b2b0-93f0e61122ca")

    var imageData:Data?

    var image:Image? {
        if let data = imageData,  data.count > 0 {
            let uiimage = UIImage(data: data)!
            return Image(uiImage:uiimage)
        }
        return nil
    }
}

struct SpotifyTrackInfo: Codable {
    
    public static let characteristicUUID = CBUUID.init(string: "c4250402-fb4b-4746-b2b0-93f0e61122c9")

    var title:String
    var artist:String
    var album:String
    var position:Int = 0
    var duration:Int = 0
    
    var data:Data? {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            print("error: \(error.localizedDescription)")
            return nil
        }
    }
    
    public static func fromData(_ json:Data) -> SpotifyTrackInfo? {
        do {
            return try JSONDecoder().decode(SpotifyTrackInfo.self, from:json)
        } catch {
            print("error: \(error.localizedDescription)")
            return nil
        }
    }
}

extension TimeInterval {
    
    var minuteSecond: String {
        String(format:"%d:%02d", minute, second)
    }

    var minute: Int {
        Int(floor(self/1000/60))
    }
    var second: Int {
        Int(floor(self/1000 - Double((self.minute * 60))))
    }
    
}
