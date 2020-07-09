//
//  UIViewController.swift
//  Pods
//
//  Created by asharijuang on 18/12/19.
//

#if os(iOS)
import UIKit
#endif
import Foundation

extension UIViewController {

    func qiscusAutoHideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.qiscusDismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func qiscusDismissKeyboard() {
        view.endEditing(true)
    }

    func showLoading(withText text: String = "Please wait...") {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    func dismissLoading() {
        dismiss(animated: false, completion: nil)
    }
    
}


extension CAGradientLayer {
    class func gradientLayerForBounds(_ bounds: CGRect, topColor:UIColor, bottomColor:UIColor) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.frame = bounds
        layer.colors = [topColor.cgColor, bottomColor.cgColor]
        return layer
    }
}

extension UINavigationBar {
    
    func verticalGradientColor(_ topColor:UIColor, bottomColor:UIColor){
        var updatedFrame = self.bounds
        // take into account the status bar
        updatedFrame.size.height += 20
        
        let layer = CAGradientLayer.gradientLayerForBounds(updatedFrame, topColor: topColor, bottomColor: bottomColor)
        UIGraphicsBeginImageContext(layer.bounds.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.barTintColor = UIColor.clear
        self.setBackgroundImage(image, for: UIBarMetrics.default)
    }
}

extension UINavigationItem {

    func setTitleWithSubtitle(title:String, subtitle : String){
        
        let titleWidth = UIScreen.main.bounds.size.width - 120
        
        let titleLabel = UILabel(frame:CGRect(x: 0, y: 0, width: titleWidth, height: 0))
        titleLabel.backgroundColor = UIColor.clear
//        titleLabel.textColor = ChatViewController().currentNavbarTint
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.tag = 502
        titleLabel.sizeToFit()
        
        let subTitleLabel = UILabel(frame:CGRect(x: 0, y: 18, width: titleWidth, height: 0))
        subTitleLabel.backgroundColor = UIColor.clear
//        subTitleLabel.textColor = ChatViewController().currentNavbarTint
        subTitleLabel.font = UIFont.systemFont(ofSize: 11)
        subTitleLabel.text = subtitle
        subTitleLabel.tag = 402
        subTitleLabel.textAlignment = .center
        subTitleLabel.sizeToFit()

        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: titleWidth, height: 30))
        
        //if titleLabel.frame.width > titleWidth {
            var adjustmentTitle = titleLabel.frame
            adjustmentTitle.size.width = titleWidth
            titleLabel.frame = adjustmentTitle
        //}
        //if subTitleLabel.frame.width > titleWidth {
            var adjustmentSubtitle = subTitleLabel.frame
            adjustmentSubtitle.size.width = titleWidth
            subTitleLabel.frame = adjustmentSubtitle
        //}
        
        titleView.addSubview(titleLabel)
        titleView.addSubview(subTitleLabel)
        
        self.titleView = titleView
        
    }

}

extension UINavigationController {
    func pushIgnorePreviousVC(to target: UIViewController, except exceptVc: AnyClass) {
        var newVC: [UIViewController ] = []
        for vc in self.viewControllers {
            if vc.isKind(of: exceptVc.self) {
                newVC.append(vc)
            }
        }
        newVC.append(target)
        self.viewControllers = newVC
    }
}

extension UIApplication {

    class func currentViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return currentViewController(nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController, top.view.window != nil {
                return currentViewController(top)
            } else if let selected = tab.selectedViewController {
                return currentViewController(selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return currentViewController(presented)
        }
        
        return base
    }
}

extension UIBaseChatCell {
    
    func getBallon()->UIImage?{
        var balloonImage:UIImage? = nil
        var edgeInset = UIEdgeInsets(top: 13, left: 13, bottom: 13, right: 28)
        
        if (self.comment?.isMyComment() == true){
            balloonImage = AssetsConfiguration.rightBallonLast
        }else{
            edgeInset = UIEdgeInsets(top: 13, left: 28, bottom: 13, right: 13)
            balloonImage = AssetsConfiguration.leftBallonLast
        }
        
        return balloonImage?.resizableImage(withCapInsets: edgeInset, resizingMode: .stretch).withRenderingMode(.alwaysTemplate)
    }
    
}

class AssetsConfiguration: NSObject {
    
    var emptyChat:UIImage = UIImage(named: "empty-chat")!.withRenderingMode(.alwaysTemplate)
    
    // MARK: - Chat balloon
    static var leftBallonLast:UIImage? = UIImage(named: "text_balloon_last_l")
    static var leftBallonNormal:UIImage? = UIImage(named: "text_balloon_left")
    static var rightBallonLast:UIImage? = UIImage(named: "text_balloon_last_r")
    static var rightBallonNormal:UIImage? = UIImage(named: "text_balloon_right")
    static var backgroundChat:UIImage? = UIImage(named: "chat_bg")
}
