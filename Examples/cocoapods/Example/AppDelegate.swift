//
//  AppDelegate.swift
//  Example
//
//  Created by asharijuang on 28/02/20.
//  Copyright © 2020 qiscus. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
       // MARK : Setup Push Notification
        if  #available(iOS 10.0,  *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate  =  self
            let  authOptions:  UNAuthorizationOptions  = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options:  authOptions,
                completionHandler: {_,  _  in })
        } else {
            let  settings:  UIUserNotificationSettings  =
            UIUserNotificationSettings(types: [.alert, .badge, .sound],  categories:  nil)
            application.registerUserNotificationSettings(settings)
        }
          
        // MARK : register the app for remote notifications
        application.registerForRemoteNotifications()
        application.unregisterForRemoteNotifications()
        // Override point for customization after application launch.
        return true
    }
    
    func  application(_  application:  UIApplication,  didRegisterForRemoteNotificationsWithDeviceToken  deviceToken:  Data) {

        ChatManager.shared.register(deviceToken:  deviceToken)

    }

    func  application(_  application:  UIApplication,  didReceiveRemoteNotification  userInfo: [AnyHashable  :  Any]) {
        ChatManager.shared.userTapNotification(userInfo: userInfo)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // print
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func  userNotificationCenter(_  center:  UNUserNotificationCenter, willPresent  notification:  UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->  Void) {

        completionHandler([.alert, .sound, .badge])
    }

    func  userNotificationCenter(_  center:  UNUserNotificationCenter, didReceive  response:  UNNotificationResponse, withCompletionHandler  completionHandler: @escaping () ->  Void) {
    
        let  userInfo  =  response.notification.request.content.userInfo
        ChatManager.shared.userTapNotification(userInfo:  userInfo)
        completionHandler()
    }
}

