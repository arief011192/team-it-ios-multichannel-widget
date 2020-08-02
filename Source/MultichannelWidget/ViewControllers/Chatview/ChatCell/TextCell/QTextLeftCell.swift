//
//  QTextLeftCell.swift
//  Qiscus
//
//  Created by asharijuang on 04/09/18.
//

#if os(iOS)
import UIKit
#endif

import QiscusCore

class QTextLeftCell: UIBaseChatCell, UITextViewDelegate {
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var tvContent: UILabel!
    @IBOutlet weak var ivBubbleLeft: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var tvContent2: UITextView!
    @IBOutlet weak var lbNameHeight: NSLayoutConstraint!
    @IBOutlet weak var lbNameLeading: NSLayoutConstraint!
    @IBOutlet weak var lbNameTrailing: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    var isPublic: Bool = false
    var menuConfig = enableMenuConfig()
    var colorName : UIColor = UIColor.black
    var openUrl: ((URL) -> Void)? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setMenu()
        self.tvContent2.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.setMenu()
        // Configure the view for the selected state
        self.tvContent2.delegate = self
    }
    
    override func present(message: QMessage) {
        // parsing payload
        self.bindData(message: message)
        
    }
    
    override func update(message: QMessage) {
        self.bindData(message: message)
    }
    
    func bindData(message: QMessage){
        self.setupBalon()
        
        self.lbTime.text = self.hour(date: message.date())
        self.lbTime.textColor = ColorConfiguration.timeLabelTextColor
        self.tvContent.text = message.message
        self.tvContent.textColor = ColorConfiguration.leftBubbleTextColor
        
        self.tvContent2.attributedText = NSAttributedString(string: message.message)
        self.tvContent2.textColor = ColorConfiguration.leftBubbleTextColor
        
        if(isPublic == true){
            self.lbName.text = message.sender.name
            self.lbName.textColor = colorName
            lbNameHeight.constant = 21
        }else{
            self.lbName.text = ""
            lbNameHeight.constant = 0
        }
    }
    
    func setupBalon(){
        self.ivBubbleLeft.applyShadow()
        self.ivBubbleLeft.image = self.getBallon()
        self.ivBubbleLeft.tintColor = ColorConfiguration.leftBubbleColor
        self.ivBubbleLeft.backgroundColor = ColorConfiguration.leftBubbleColor
        self.ivBubbleLeft.layer.cornerRadius = 5.0
        self.ivBubbleLeft.clipsToBounds = true
    }
    
    func hour(date: Date?) -> String {
        guard let date = date else {
            return "-"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone      = TimeZone.current
        let defaultTimeZoneStr = formatter.string(from: date);
        return defaultTimeZoneStr
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if openUrl != nil {
            self.openUrl!(URL)
        }
        return false
    }

}
