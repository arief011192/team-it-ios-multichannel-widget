//
//  QismoManager.swift
//  BBChat
//
//  Created by asharijuang on 17/12/19.
//

#if os(iOS)
import UIKit
#endif
import Foundation
import QiscusCoreAPI
import SwiftyJSON
import UserNotifications

class QismoManager {
    
    static let shared : QismoManager = QismoManager()
    
    var appID: String = ""
    private var userID : String = ""
    private var username : String = ""
    private var avatarUrl: String = ""
    var network : QismoNetworkManager!
    var qiscus : QiscusCoreAPI!
    var qiscusServer = QiscusServer(url: URL(string: "https://api.qiscus.com")!, realtimeURL: "", realtimePort: 80)
    var deviceToken : String = "" // save device token for 1st time or before login
    
    
    func setUser(id: String, username: String, avatarUrl: String = "") {
        self.userID = id
        self.username = username
        self.avatarUrl = avatarUrl
    }
    
    func clear() {
        self.userID = ""
        self.username = ""
        self.qiscus.signOut()
        SharedPreferences.removeRoomId()
    }
    
    func setup(appID: String, server : QiscusServer? = nil) {
        self.appID = appID
        self.qiscus = QiscusCoreAPI.init(withAppId: appID, server: qiscusServer)
        self.network = QismoNetworkManager(QiscusCoreAPI: self.qiscus)
        if let _server = server {
            self.qiscusServer = _server
        }
    }
    
    func initiateChat(withTitle title: String, andSubtitle subtitle: String, userId: String? = nil, username: String? = nil,avatar: String? = nil, extras: String? = nil, userProperties: [[String:Any]]? = nil, callback: @escaping (UIViewController) -> Void)  {
        let savedRoomId = SharedPreferences.getRoomId()
        
        if savedRoomId != nil {
            let ui = UIChatViewController()
            ui.roomId = savedRoomId!
            ui.chatTitle = title
            ui.chatSubtitle = subtitle
            callback(ui)
            return
        }
        
        let param = [
            "app_id"            : appID,
            "user_id"           : userId ?? self.userID,
            "name"              : username ?? self.username,
            "avatar"            : avatar ?? self.avatarUrl,
            "extras"            : extras ?? "{}",
            "user_properties"   : userProperties != nil ? userProperties ?? [] : [],
            "nonce"             : ""
            ] as [String : Any]
        
        self.network.initiateChat(param: param as [String : Any], onSuccess: { roomId in
            
            SharedPreferences.saveParam(param: param)
            SharedPreferences.saveRoomId(id: roomId)
            let ui = UIChatViewController()
            ui.roomId = roomId
            ui.chatTitle = title
            ui.chatSubtitle = subtitle
            callback(ui)
            
            // check device token
            if !self.deviceToken.isEmpty {
                self.qiscus.register(deviceToken: self.deviceToken, isDevelopment: false, onSuccess: { (success) in
                    if success { self.deviceToken = "" }
                }) { (error) in
                    //
                }
            }
        }, onError: { error in
            debugPrint("failed initiate chat, \(error)")
        })
        
    }
    
    
    /// Go to Chat user room id. Example when tap notification
    /// - Parameters:
    ///   - id: Room id
    ///   - title: navigation title
    ///   - subtitle: navigation subtitle
    func chatViewController(withRoomId id:String, Title title: String, andSubtitle subtitle: String, callback: @escaping (UIViewController) -> Void) {
        let ui = UIChatViewController()
        ui.roomId = id
        ui.chatTitle = title
        ui.chatSubtitle = subtitle
        callback(ui)
    }
    
    func isMultichannelNotification(userInfo: [AnyHashable : Any]) -> Bool {
        let json = JSON(userInfo)
        print(json)
        guard let payload = json["payload"].dictionary, let app_code = payload["app_code"]?.string else { return false }
        return app_code == self.appID
    }
    
    // MARK : Push Notifications
    func handleNotification(userInfo: [AnyHashable : Any], removePreviousNotif: Bool) {
        let json = JSON(userInfo)
        print(json)
        
        if !isMultichannelNotification(userInfo: userInfo) { return }
        
        if let qiscusEvent = json["qiscus_sdk"].string, qiscusEvent == "post_comment" {
            let roomId = json["qiscus_room_id"].intValue
            if removePreviousNotif {
                self.removeNotification(withRoom: roomId)
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
               self.redirectToChat(roomID: roomId)
            }
        }
        // mybe for another notif
    }
    
    @available(*, deprecated, message: "Not relevan, since user can config chat view with title and color")
    private func redirectToChat(roomID id: Int) {
        let current = UIApplication.currentViewController()
        let target = UIChatViewController()
        // MARK: TODO get qiscus room from local db
        target.roomId = String(id)
        current?.navigationController?.pushViewController(target, animated: true)
    }
    
    private func removeNotification(withRoom id: Int) {
        // remove all notification in room
        let notif = UNUserNotificationCenter.current()
        notif.getDeliveredNotifications { (n) in
            n.forEach { (notification) in
                let info = notification.request.content.userInfo
                let _json = JSON(info)
                let _roomId = _json["qiscus_room_id"].intValue
                if _roomId == id {
                    // remove notification with identifier for samem room id
                    notif.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
                }
            }
        }
    }
    
    
}
