//
//  SharedPreferences.swift
//  Pods
//
//  Created by qiscus on 26/04/20.
//

import Foundation

class SharedPreferences {
    
    static let defaults = UserDefaults.standard
    
    static func saveRoomId(id: String) {
        defaults.set(id, forKey: "multichannel_room_id")
    }
    
    static func getRoomId() -> String? {
        return defaults.string(forKey: "multichannel_room_id")
    }
    
    static func saveParam(param: [String:Any]) {
        defaults.set(param, forKey: "multichannel_param")
    }
    
    static func getParam() -> [String: Any]? {
        return defaults.dictionary(forKey: "multichannel_param")
    }
    
    static func removeRoomId() {
        defaults.set(nil, forKey: "multichannel_room_id")
    }
}
