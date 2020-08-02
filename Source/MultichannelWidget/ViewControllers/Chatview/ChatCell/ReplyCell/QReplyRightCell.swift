//
//  QReplyRightCell.swift
//  Qiscus
//
//  Created by asharijuang on 05/09/18.
//

#if os(iOS)
import UIKit
#endif
import QiscusCoreAPI
import SwiftyJSON

class QReplyRightCell: UIBaseChatCell {
    @IBOutlet weak var viewReplyPreview: UIView!
    @IBOutlet weak var ivCommentImageWidhtCons: NSLayoutConstraint!
    @IBOutlet weak var lbCommentSender: UILabel!
    @IBOutlet weak var tvCommentContent: UITextView!
    @IBOutlet weak var ivCommentImage: UIImageView!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var lbContent: UILabel!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var ivBubble: UIImageView!
    @IBOutlet weak var ivStatus: UIImageView!
    var menuConfig = enableMenuConfig()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setMenu()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        
        viewReplyPreview.addGestureRecognizer(tap)
        viewReplyPreview.isUserInteractionEnabled = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.setMenu()
        // Configure the view for the selected state
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        
    }
    
    override func present(message: CommentModel) {
        // parsing payload
        self.bindData(message: message)
        
    }
    
    override func update(message: CommentModel) {
        self.bindData(message: message)
    }
    
    func bindData(message: CommentModel){
        self.setupBalon()
        self.status(message: message)
        
        guard let replyData = message.payload else {
            return
        }
        var text = replyData["replied_comment_message"] as? String
        var replyType = message.replyType(message: text!)
        
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
            self.ivCommentImage.image       = UIImage(named: "ic_file_white" , in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            self.ivCommentImage.contentMode = .scaleAspectFit
            self.ivCommentImage.tintColor   = #colorLiteral(red: 0.4077942371, green: 0.4078705907, blue: 0.4077951014, alpha: 1)
        case .audio:
            self.tvCommentContent.text = text
        case .document:
            //pdf
            self.ivCommentImage.image = UIImage(named: "ic_file_white" , in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
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
        case .file:
            let url = message.getAttachmentURL(message: text ?? "")
            self.tvCommentContent.text      = message.fileName(text: url)
            self.ivCommentImage.image = UIImage(named: "ic_file_white" , in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            self.ivCommentImage.contentMode = .scaleAspectFit
            self.ivCommentImage.tintColor = #colorLiteral(red: 0.4077942371, green: 0.4078705907, blue: 0.4077951014, alpha: 1)
        case .other:
            self.tvCommentContent.text = text
            self.ivCommentImageWidhtCons.constant = 0
        }
        
        
        self.lbContent.text = message.message
        self.lbTime.text = self.hour(date: message.date())
        if(message.isMyComment() == true){
            self.lbName.text = "You"
        }else{
            self.lbName.text = message.username
        }
        
        guard let user = QismoManager.shared.qiscus.userProfile else { return }
        if repliedEmail == user.email {
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
        self.ivBubble.tintColor = ColorConfiguration.rightBubbleColor
        self.ivBubble.backgroundColor = ColorConfiguration.rightBubbleColor
        self.viewReplyPreview.backgroundColor = .white
        self.ivBubble.layer.cornerRadius = 5.0
        self.ivBubble.clipsToBounds = true
//        self.lbTime.textColor = ColorConfiguration.timeLabelTextColor
    }
    
    func status(message: CommentModel){
        
        switch message.status {
        case .deleted:
            ivStatus.image = UIImage(named: "ic_deleted", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        case .sending, .pending:
            lbTime.textColor = ColorConfiguration.timeLabelTextColor
            ivStatus.tintColor = ColorConfiguration.timeLabelTextColor
            lbTime.text = TextConfiguration.sharedInstance.sendingText
            ivStatus.image = UIImage(named: "ic_info_time", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        case .sent:
            lbTime.textColor = ColorConfiguration.timeLabelTextColor
            ivStatus.tintColor = ColorConfiguration.timeLabelTextColor
            ivStatus.image = UIImage(named: "ic_sending", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        case .delivered:
            lbTime.textColor = ColorConfiguration.timeLabelTextColor
            ivStatus.tintColor = ColorConfiguration.timeLabelTextColor
            ivStatus.image = UIImage(named: "ic_read", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        case .read:
            lbTime.textColor = ColorConfiguration.timeLabelTextColor
            ivStatus.tintColor = ColorConfiguration.readMessageColor
            ivStatus.image = UIImage(named: "ic_read", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        case . failed:
            lbTime.textColor = ColorConfiguration.failToSendColor
            lbTime.text = TextConfiguration.sharedInstance.failedText
            ivStatus.image = UIImage(named: "ic_warning", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            ivStatus.tintColor = ColorConfiguration.failToSendColor
            break
        case .deleting:
            ivStatus.image = UIImage(named: "ic_deleted", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        }
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
