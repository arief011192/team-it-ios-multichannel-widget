//
//  Qismo.swift
//  Alamofire
//
//  Created by asharijuang on 08/01/20.
//

import Foundation
#if os(iOS)
import UIKit
#endif
import Alamofire
import QiscusCoreAPI

public class MultichannelWidget {
    
    static var bundle:Bundle{
        get{
            let podBundle = Bundle(for: MultichannelWidget.self)
            
            if let bundleURL = podBundle.url(forResource: "MultichannelWidget", withExtension: "bundle") {
                return Bundle(url: bundleURL)!
            }else{
                return podBundle
            }
        }
    }
    
    let widgetConfig: MultichannelWidgetConfig
    let manager : QismoManager = QismoManager.shared
    
    public init(appID: String, server : QiscusServer? = nil) {
        self.manager.setup(appID: appID, server: server)
        self.widgetConfig = MultichannelWidgetConfig()
    }
    
    public func setUser(id: String, displayName: String, avatarUrl: String = "") {
        self.manager.setUser(id: id, username: displayName, avatarUrl: avatarUrl)
    }
    
    /// Clear all user data or logout
    public func clearUser() {
        self.manager.clear()
    }
    
    @available(*, deprecated, message: "Please replace with initiateChat")
    public func prepareChat(withTitle title: String, andSubtitle subtitle: String) -> MultichannelWidgetConfig {
        widgetConfig.title = title
        widgetConfig.subtitle = subtitle
        return widgetConfig
    }
    
    public func initiateChat(withTitle title: String, andSubtitle subtitle: String) -> MultichannelWidgetConfig {
        widgetConfig.title = title
        widgetConfig.subtitle = subtitle
        return widgetConfig
    }
    
    public func register(deviceToken token: String, onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void){
        self.manager.deviceToken = token
        manager.qiscus.register(deviceToken: token, isDevelopment: false, onSuccess: { (response) in
            if response { self.manager.deviceToken = "" }
            onSuccess(response)
        }) { (error) in
            onError(error.message)
        }
    }
    
    public func isLoggedIn() -> Bool {
        return manager.qiscus.isLogined
    }
    
    public func isMultichannelNotification(userInfo: [String:Any]) -> Bool {
        // check app id
        return false
    }
    
    public func isMultichannelNotification(userInfo: [AnyHashable : Any]) -> Bool {
        return manager.isMultichannelNotification(userInfo: userInfo)
    }
    
    public func handleNotification(userInfo : [AnyHashable : Any], removePreviousNotif: Bool) {
        manager.handleNotification(userInfo: userInfo, removePreviousNotif: removePreviousNotif)
    }
    
}
