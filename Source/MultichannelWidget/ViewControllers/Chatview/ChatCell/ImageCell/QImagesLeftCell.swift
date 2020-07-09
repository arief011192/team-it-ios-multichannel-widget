//
//  QImagesLeftCell.swift
//  BBChat
//
//  Created by qiscus on 13/01/20.
//

#if os(iOS)
import UIKit
#endif
import QiscusCoreAPI
import Alamofire
import AlamofireImage

class QImagesLeftCell: UIBaseChatCell {
    
    @IBOutlet weak var lblCaption: UILabel!
    @IBOutlet weak var ivLeftBubble: UIImageView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var ivComment: UIImageView!
    
    var isPublic: Bool = false
    var menuConfig = enableMenuConfig()
    var colorName : UIColor = UIColor.black
    
    var actionBlock: ((CommentModel) -> Void)? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setMenu()
        self.ivComment.isUserInteractionEnabled = true
        let imgTouchEvent = UITapGestureRecognizer(target: self, action: #selector(QImagesLeftCell.imageDidTap))
        self.ivComment.addGestureRecognizer(imgTouchEvent)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.setMenu()
        // Configure the view for the selected state
    }
    
    override func present(message: CommentModel) {
        self.bindData(message: message)
    }
    
    override func update(message: CommentModel) {
        self.bindData(message: message)
    }
    
    func setupBalon(){
        self.ivLeftBubble.applyShadow()
        self.ivLeftBubble.image = self.getBallon()
        self.ivLeftBubble.tintColor = ColorConfiguration.leftBubbleColor
        self.ivLeftBubble.backgroundColor = ColorConfiguration.leftBubbleColor
        self.ivLeftBubble.layer.cornerRadius = 5.0
        self.ivLeftBubble.clipsToBounds = true
        
    }
    
    func bindData(message: CommentModel) {
        setupBalon()
        self.lblDate.text = AppUtil.dateToHour(date: message.date())
        self.lblDate.textColor = ColorConfiguration.timeLabelTextColor
        guard let payload = message.payload else { return }

        let caption = payload["caption"] as? String
        if caption != nil {
            self.lblCaption.text = caption
        } else {
            self.lblCaption.isHidden = false
        }

        if let url = payload["url"] as? String {
            if self.ivComment.image == nil {
                self.ivComment.af.setImage(withURL: URL(string: url)!)
            }
        }
    }
    
    @objc func imageDidTap() {
        if self.comment != nil && self.actionBlock != nil {
            self.actionBlock!(comment!)
        }
    }
    
}
