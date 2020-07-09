//
//  MultichannelWidgetConfig.swift
//  MultichannelWidget
//
//  Created by Rahardyan Bisma on 19/05/20.
//

#if os(iOS)
import UIKit
#endif
import Foundation

open class MultichannelWidgetConfig {
    private var avatar: String = ""
    private var extras: String = ""
    var title: String = ""
    var subtitle: String = ""
    private var userProperties: [[String : String]] = []
    private var rightBubblColor: UIColor = ColorConfiguration.rightBubbleColor
    private var leftBubblColor: UIColor = ColorConfiguration.leftBubbleColor
    private var navigationColor: UIColor? = nil
    private var navigationTitleColor: UIColor = ColorConfiguration.navigationTitleColor
    private var systemBalloonColor: UIColor = ColorConfiguration.systemBubbleColor
    private var systemBalloonTextColor: UIColor = ColorConfiguration.systemBubbleTextColor
    private var leftBubblTextColor: UIColor = ColorConfiguration.leftBubbleTextColor
    private var rightBubblTextColor: UIColor = ColorConfiguration.rightBubbleTextColor
    private var timeLabelTextColor: UIColor = ColorConfiguration.timeLabelTextColor
    private var baseColor: UIColor = ColorConfiguration.baseColor
    private var emptyChatBackgroundColor: UIColor = ColorConfiguration.emptyChatBackgroundColor
    private var emptyChatTextColor: UIColor = ColorConfiguration.emptyChatTextColor
    
    public func setExtras(extras: String) -> MultichannelWidgetConfig {
        self.extras = extras
        return self
    }
    
    public func setNavigation(title: String, subtitle: String) -> MultichannelWidgetConfig {
        self.title = title
        self.subtitle = subtitle
        return self
    }
    
    public func setUserProperties(properties: [[String : String]]) -> MultichannelWidgetConfig {
        self.userProperties = properties
        return self
    }
    
    public func setAvatar(avatarUrl: String) -> MultichannelWidgetConfig {
           self.avatar = avatarUrl
           return self
       }
    
    public func setRightBubbleColor(color: UIColor) -> MultichannelWidgetConfig {
        self.rightBubblColor = color
        return self
    }
    
    public func setRightBubblTextColor(color: UIColor) -> MultichannelWidgetConfig {
        self.rightBubblTextColor = color
        return self
    }
    
    public func setLeftBubbleColor(color: UIColor) -> MultichannelWidgetConfig {
        self.leftBubblColor = color
        return self
    }
    
    public func setLeftBubblTextColor(color: UIColor) -> MultichannelWidgetConfig {
        self.leftBubblTextColor = color
        return self
    }
    
    public func setSystemBubblColor(color: UIColor) -> MultichannelWidgetConfig {
        self.systemBalloonColor = color
        return self
    }
    
    public func setSystemBubblTextColor(color: UIColor) -> MultichannelWidgetConfig {
        self.systemBalloonTextColor = color
        return self
    }
    
    public func setTimeLabelTextColor(color: UIColor) -> MultichannelWidgetConfig {
        self.timeLabelTextColor = color
        return self
    }
    
    public func setNavigationColor(color: UIColor) -> MultichannelWidgetConfig {
        self.navigationColor = color
        return self
    }
    
    public func setNavigationTitleColor(color: UIColor) -> MultichannelWidgetConfig {
        self.navigationTitleColor = color
        return self
    }
    
    public func setBaseColor(color: UIColor) -> MultichannelWidgetConfig {
        self.baseColor = color
        return self
    }
    
    public func setEmptyBackgroundColor(color: UIColor) -> MultichannelWidgetConfig {
        self.emptyChatBackgroundColor = color
        return self
    }
    
    public func setEmptyTextColor(color: UIColor) -> MultichannelWidgetConfig {
        self.emptyChatTextColor = color
        return self
    }
    
    public func startChat(callback: @escaping (UIViewController) -> Void) {
        ColorConfiguration.navigationColor = self.navigationColor
        ColorConfiguration.navigationTitleColor = self.navigationTitleColor
        ColorConfiguration.rightBubbleColor = self.rightBubblColor
        ColorConfiguration.leftBubbleColor = self.leftBubblColor
        ColorConfiguration.systemBubbleColor = self.systemBalloonColor
        ColorConfiguration.systemBubbleTextColor = self.systemBalloonTextColor
        ColorConfiguration.leftBubbleTextColor = self.leftBubblTextColor
        ColorConfiguration.rightBubbleTextColor = self.rightBubblTextColor
        ColorConfiguration.timeLabelTextColor = self.timeLabelTextColor
        ColorConfiguration.baseColor = self.baseColor
        ColorConfiguration.emptyChatTextColor = self.emptyChatTextColor
        ColorConfiguration.emptyChatBackgroundColor = self.emptyChatBackgroundColor
        
        QismoManager.shared.initiateChat(withTitle: self.title, andSubtitle: self.subtitle, extras: self.extras, userProperties: self.userProperties, callback: callback)
    }
    
    public func startChat(withRoomId id: String, callback: @escaping (UIViewController) -> Void) {
        ColorConfiguration.navigationColor = self.navigationColor
        ColorConfiguration.navigationTitleColor = self.navigationTitleColor
        ColorConfiguration.rightBubbleColor = self.rightBubblColor
        ColorConfiguration.leftBubbleColor = self.leftBubblColor
        ColorConfiguration.systemBubbleColor = self.systemBalloonColor
        ColorConfiguration.systemBubbleTextColor = self.systemBalloonTextColor
        ColorConfiguration.leftBubbleTextColor = self.leftBubblTextColor
        ColorConfiguration.rightBubbleTextColor = self.rightBubblTextColor
        ColorConfiguration.timeLabelTextColor = self.timeLabelTextColor
        ColorConfiguration.baseColor = self.baseColor
        ColorConfiguration.emptyChatTextColor = self.emptyChatTextColor
        ColorConfiguration.emptyChatBackgroundColor = self.emptyChatBackgroundColor
        
        QismoManager.shared.chatViewController(withRoomId: id, Title: self.title, andSubtitle: self.subtitle) { (chatview) in
            callback(chatview)
        }
    }
}
