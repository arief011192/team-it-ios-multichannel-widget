//
//  ChatManager.swift
//  Example
//
//  Created by Rahardyan Bisma on 19/05/20.
//  Copyright © 2020 qiscus. All rights reserved.
//

import Foundation
import UIKit
import MultichannelWidget

enum ChatTransitionType {
    case push(animated: Bool)
    case present(animated: Bool, completion: (() -> Void)? = nil)
}

final class ChatManager {
    static let shared: ChatManager = ChatManager()
    
    lazy var widget: MultichannelWidget = {
       return MultichannelWidget(appID: "karm-gzu41e4e4dv9fu3f")
    }()
    
    func setUser(id: String, displayName: String, avatarUrl: String = "") {
        widget.setUser(id: id, displayName: displayName, avatarUrl: avatarUrl)
    }
    
    func signOut() {
        widget.clearUser()
    }
    
    func isLoggedIn() -> Bool {
        return widget.isLoggedIn()
    }
    
    func startChat(from viewController: UIViewController, extras: String = "", userProperties: [[String: String]] = [], transition: ChatTransitionType = .push(animated: true)) {
        
        widget.prepareChat(withTitle: "Customer Care", andSubtitle: "ready to serve")
            .setNavigationColor(color: #colorLiteral(red: 0.2202146215, green: 0.6294460518, blue: 0.9050356218, alpha: 1))
            .setNavigationTitleColor(color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
            .setRightBubbleColor(color: #colorLiteral(red: 0.2202146215, green: 0.6294460518, blue: 0.9050356218, alpha: 1))
            .setLeftBubbleColor(color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
            .setRightBubblTextColor(color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
            .setLeftBubblTextColor(color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
            .setTimeLabelTextColor(color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
            .setBaseColor(color: #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1))
            .setEmptyTextColor(color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
            .setEmptyBackgroundColor(color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
            .startChat { (chatViewController) in
                viewController.navigationController?.pushViewController(chatViewController, animated: true)
        }
        widget.clearUser()
    }
    
    func register(deviceToken: Data?) {
        if let deviceToken = deviceToken {
            var tokenString: String = ""
            for i in 0..<deviceToken.count {
                tokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
            }
            print("token = \(tokenString)")
            self.widget.register(deviceToken: tokenString, onSuccess: { (response) in
                print("Multichannel widget success to register device token")
            }) { (error) in
                print("Multichannel widget failed to register device token")
            }
        }
    }
    
    
    func userTapNotification(userInfo : [AnyHashable : Any]) {
        self.widget.tapNotification(userInfo: userInfo)
    }
}
