//
//  QReplyLeftCell.swift
//  Qiscus
//
//  Created by asharijuang on 05/09/18.
//

#if os(iOS)
import UIKit
#endif
import QiscusCore
import SwiftyJSON
import AlamofireImage

class QReplyLeftCell: UIBaseChatCell {
    
    @IBOutlet weak var viewReplyPreview: UIView!
    @IBOutlet weak var lblNameHeightCons: NSLayoutConstraint!
    @IBOutlet weak var ivCommentImageWidhtCons: NSLayoutConstraint!
    @IBOutlet weak var lbCommentSender: UILabel!
    @IBOutlet weak var tvCommentContent: UITextView!
    @IBOutlet weak var ivCommentImage: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var lbContent: UILabel!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var ivBubble: UIImageView!
    var menuConfig = enableMenuConfig()
    var isPublic: Bool = false
    var colorName : UIColor = UIColor.black
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setMenu()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        
        viewReplyPreview.addGestureRecognizer(tap)
        viewReplyPreview.isUserInteractionEnabled = true
        ivCommentImage.clipsToBounds = true
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
//        if let delegate = delegateChat {
//            guard let replyData = self.comment?.payload else {
//                return
//            }
//            let json = JSON(replyData)
//            var commentID = json["replied_comment_id"].int ?? 0
//            if commentID != 0 {
//                if let comment = QiscusCore.database.comment.find(id: "\(commentID)"){
//                    delegate.scrollToComment(comment: comment)
//                }
//            }
//        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.setMenu()
        // Configure the view for the selected state
    }
    
    override func present(message: QMessage) {
        // parsing payload
        self.bindData(message: message)
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.ivCommentImageWidhtCons.constant = 50
    }
    
    override func update(message: QMessage) {
        self.bindData(message: message)
    }
    
    func bindData(message: QMessage){
        self.setupBalon()
        guard let replyData = message.payload else {
           return
        }
        let text = replyData["replied_comment_message"] as? String
        var replyType = message.replyType(message: text!)
        lbCommentSender.text = replyData["replied_comment_sender_username"] as? String
        
        if replyType == .text  {
            switch replyData["replied_comment_type"] as? String {
            case "location":
                replyType = .location
                break
            case "contact_person":
                replyType = .contact
                break
            default:
                break
            }
        }
        var username = replyData["replied_comment_sender_username"] as? String
        let repliedEmail = replyData["replied_comment_sender_email"] as? String
        
        switch replyType {
        case .text:
            self.ivCommentImageWidhtCons.constant = 0
            self.tvCommentContent.text = text
        case .image:
            let filename = message.fileName(text: text!)
            self.tvCommentContent.text = filename
            let url = URL(string: message.getAttachmentURL(message: text!))
            self.ivCommentImage.af.setImage(withURL: url!)
            
        case .video:
            let url = message.getAttachmentURL(message: text ?? "")
            self.tvCommentContent.text      = message.fileName(text: url)
            self.ivCommentImage.image       = UIImage(named: "ic_file_black" , in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            self.ivCommentImage.contentMode = .scaleAspectFit
            self.ivCommentImage.tintColor   = #colorLiteral(red: 0.4077942371, green: 0.4078705907, blue: 0.4077951014, alpha: 1)
        case .audio:
            self.tvCommentContent.text = text
        case .document:
            //pdf
            self.ivCommentImage.image = UIImage(named: "ic_file_black" , in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            self.ivCommentImage.contentMode = .scaleAspectFit
            self.ivCommentImage.tintColor   = #colorLiteral(red: 0.4077942371, green: 0.4078705907, blue: 0.4077951014, alpha: 1)
            let url = message.getAttachmentURL(message: text ?? "")
            self.tvCommentContent.text      = message.fileName(text: url)
        case .location:
            self.tvCommentContent.text = text
            self.ivCommentImage.image = UIImage(named: "map_ico", in: MultichannelWidget.bundle, compatibleWith: nil)
        case .contact:
            self.tvCommentContent.text = text
            self.ivCommentImage.image = UIImage(named: "contact", in: MultichannelWidget.bundle, compatibleWith: nil)
            self.ivCommentImage.contentMode = .scaleAspectFit
            self.ivCommentImage.tintColor   = ColorConfiguration.leftBubbleColor
        case .file:
            let url = message.getAttachmentURL(message: text ?? "")
            self.tvCommentContent.text      = message.fileName(text: url)
            self.ivCommentImage.image       = UIImage(named: "ic_file_black" , in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            self.ivCommentImage.contentMode = .scaleAspectFit
            self.ivCommentImage.tintColor   = #colorLiteral(red: 0.4077942371, green: 0.4078705907, blue: 0.4077951014, alpha: 1)
        case .other:
            self.tvCommentContent.text = text
            self.ivCommentImageWidhtCons.constant = 0
        }
        
        
        self.lbContent.text = message.message
        self.lbTime.text = self.hour(date: message.date())
        if(isPublic == true){
            self.lbName.text = message.sender.name
            self.lbName.textColor = colorName
            self.lblNameHeightCons.constant = 21
        }else{
            self.lbName.text = ""
            self.lblNameHeightCons.constant = 0
        }
        if let user = QismoManager.shared.network.qiscusUser, repliedEmail == user.id {
            username = "You"
        } else if let userEmail = SharedPreferences.getQiscusAccount(), repliedEmail == userEmail {
            username = "You"
        }
        
        self.lbCommentSender.text = username
    }
    
    func getThumbUrl(_ value: String) -> URL? {
        if value.isEmpty { return nil }
        guard let original = URL(string: value)?.deletingPathExtension().absoluteString else { return nil }
        let thumbImage = original + ".png"
        return URL(string: thumbImage)
    }
    
    func setupBalon(){
        self.ivBubble.applyShadow()
        self.ivBubble.image = self.getBallon()
        self.ivBubble.tintColor = ColorConfiguration.leftBubbleColor
        self.ivBubble.backgroundColor = ColorConfiguration.leftBubbleColor
        self.viewReplyPreview.backgroundColor = .white
        self.ivBubble.layer.cornerRadius = 5.0
        self.ivBubble.clipsToBounds = true
        
        self.lbTime.textColor = ColorConfiguration.timeLabelTextColor
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
    
}
