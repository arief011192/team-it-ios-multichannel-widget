//
//  ChatTitleView.swift
//  QiscusUI
//
//  Created by Qiscus on 25/10/18.
//

#if os(iOS)
import UIKit
#endif
import QiscusCore
import AlamofireImage

class UIChatNavigation: UIView {
    var contentsView            : UIView!
    // ui component
    /// UILabel title,
    @IBOutlet weak var ivAvatar: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    /// UILabel subtitle
    @IBOutlet weak var labelSubtitle: UILabel!
    
    var room: QChatRoom? {
        set {
            self._room = newValue
            if let data = newValue { present(room: data) } // bind data only
        }
        get {
            return self._room
        }
    }
    private var _room : QChatRoom? = nil
    
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
    
    // If someone is to initialize a UIChatInput in code
    override init(frame: CGRect) {
        // For use in code
        super.init(frame: frame)
        let nib = UINib(nibName: "UIChatNavigation", bundle: MultichannelWidget.bundle)
        commonInit(nib: nib)
    }
    
    // If someone is to initalize a UIChatInput in Storyboard setting the Custom Class of a UIView
    required init?(coder aDecoder: NSCoder) {
        // For use in Interface Builder
        super.init(coder: aDecoder)
        let nib = UINib(nibName: "UIChatNavigation", bundle: MultichannelWidget.bundle)
        commonInit(nib: nib)
    }
    
    func commonInit(nib: UINib) {
        self.contentsView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        // 2. Adding the 'contentView' to self (self represents the instance of a WeatherView which is a 'UIView').
        addSubview(contentsView)
        
        // 3. Setting this false allows us to set our constraints on the contentView programtically
        contentsView.translatesAutoresizingMaskIntoConstraints = false
        
        // 4. Setting the constraints programatically
        contentsView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentsView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        contentsView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        contentsView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        self.autoresizingMask  = (UIView.AutoresizingMask.flexibleWidth)
        self.setupUI()
    }
    
    private func setupUI() {
        self.ivAvatar.layer.cornerRadius = 43/2
        self.ivAvatar.clipsToBounds = true
    }
    
    func present(room: QChatRoom) {
        
        // change avatar room do admin avatar, you can set avatar on admin dashboard
        room.participants?.forEach({ (p) in
            if p.id.contains("admin@qismo.com") {
                if let avatarURL = p.avatarUrl {
                    self.ivAvatar.af.setImage(withURL: avatarURL)
                }
            }
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}

extension UIChatNavigation {
    func getParticipant(participants: [QParticipant]) -> String {
        var result = ""
        for m in participants {
            if result.isEmpty {
                result = m.name
            }else {
                result = result + ", \(m.name)"
            }
        }
        return result
    }
}
