//
//  QCardLeftCell.swift
//  Qismo
//
//  Created by qiscus on 21/02/20.
//

#if os(iOS)
import UIKit
#endif
import QiscusCore
import AlamofireImage
import SwiftyJSON

class QCardLeftCell: UIBaseChatCell {
    
    var menuConfig = enableMenuConfig()
    
    @IBOutlet weak var stackButton: UIStackView!
    @IBOutlet weak var ivLeftBuble: UIImageView!
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var ivAttachment: UIImageView!
    
    var actionBlock: ((CustomButton) -> Void)? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setMenu()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        self.setMenu()
    }
    
    override func present(message: QMessage) {
        self.bind(message: message)
    }
    
    override func update(message: QMessage) {
        self.bind(message: message)
    }
    
    func bind(message: QMessage) {
        self.setupBalon()
        
        guard let payload = message.payload else { return }
        if let url = payload["image"] as? String {
            if self.ivAttachment.image == nil {
                self.ivAttachment.af.setImage(withURL: URL(string: url)!)
            }
        }
        
        self.lblDesc.textColor = ColorConfiguration.leftBubbleTextColor
        self.lblTitle.text = payload["title"] as? String
        self.lblDesc.text = payload["description"] as? String
        self.lblDate.text = AppUtil.dateToHour(date: message.date())
        
        //remove view if any view. happen when you scroll
        self.stackButton.subviews.forEach({
            $0.removeFromSuperview()
        })
        
        if let button = payload["buttons"] as? [[String: Any]] {
            for btn in button {
                let b = CustomButton()
                let title = btn["label"] as? String
                let payload = btn["payload"] as? [String: Any]
                let url = payload?["url"] as? String
                b.setTitle(title, for: .normal)
                b.url = url
                b.titleLabel?.font = .systemFont(ofSize: 12)
                b.setTitleColor(ColorConfiguration.baseColor, for: .normal)
                b.addTarget(self, action: #selector(btnCardClick), for: .touchUpInside)
                self.stackButton.addArrangedSubview(b)
            }
        }
        
    }
    
    @objc func btnCardClick(sender: CustomButton) {
        if sender.url != nil && self.actionBlock != nil {
            self.actionBlock!(sender)
        }
    }
    
    func setupBalon(){
        self.ivLeftBuble.applyShadow()
        self.ivLeftBuble.image = self.getBallon()
        self.ivLeftBuble.tintColor = ColorConfiguration.leftBubbleColor
        self.ivLeftBuble.backgroundColor = ColorConfiguration.leftBubbleColor
        self.ivLeftBuble.layer.cornerRadius = 5.0
        self.ivLeftBuble.clipsToBounds = true
        self.lblDate.textColor = ColorConfiguration.timeLabelTextColor
    }
    
    class CustomButton: UIButton {
        var url: String?
    }
    
}
