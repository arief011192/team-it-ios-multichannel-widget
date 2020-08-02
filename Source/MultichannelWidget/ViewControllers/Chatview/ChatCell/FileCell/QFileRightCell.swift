//
//  QFileRightCell.swift
//  BBChat
//
//  Created by qiscus on 27/01/20.
//

#if os(iOS)
import UIKit
#endif
import QiscusCore

class QFileRightCell: UIBaseChatCell {

    @IBOutlet weak var lblExtension: UILabel!
    @IBOutlet weak var ivIcon: UIImageView!
    @IBOutlet weak var lblFilename: UILabel!
    @IBOutlet weak var ivRightBubble: UIImageView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var ivStatus: UIImageView!
    
    var actionBlock: ((QMessage) -> Void)? = nil
    private var message: QMessage? = nil
    
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
    
    func setupBubble() {
        self.ivRightBubble.image = self.getBallon()
        self.ivRightBubble.tintColor = ColorConfiguration.rightBubbleColor
        self.ivRightBubble.backgroundColor = ColorConfiguration.rightBubbleColor
        
        self.lblFilename.textColor = ColorConfiguration.rightBubbleTextColor
        self.lblExtension.textColor = ColorConfiguration.rightBubbleTextColor
        self.lblDate.textColor = ColorConfiguration.timeLabelTextColor
        
        self.ivRightBubble.layer.cornerRadius = 5.0
        self.ivRightBubble.clipsToBounds = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTap))
        self.ivRightBubble.addGestureRecognizer(tapGesture)
        self.ivRightBubble.isUserInteractionEnabled = true
    }
    
    @objc private func didTap() {
        guard let message = self.message else {
            return
        }
        
        self.actionBlock?(message)
    }
    
    func bind(message: QMessage) {
        self.message = message
        self.setupBubble()
        self.status(message: message)
        
        guard let payload = message.payload else { return }
        
        self.ivIcon.image = UIImage(named: "ic_file_white", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal)
        let url = payload["url"] as? String
        
        self.lblFilename.text = payload["file_name"] as? String
        self.lblDate.text = AppUtil.dateToHour(date: message.timestamp)
        self.lblExtension.text = ("\(message.fileExtension(fromURL: url!)) file")
    }
    
    func status(message: QMessage){
        
        switch message.status {
        case .deleted:
//                        ivStatus.image = UIImage(named: "ic_deleted", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        case .sending, .pending:
            lblDate.textColor = ColorConfiguration.timeLabelTextColor
                        ivStatus.tintColor = ColorConfiguration.timeLabelTextColor
            lblDate.text = TextConfiguration.sharedInstance.sendingText
            ivStatus.image = UIImage(named: "ic_info_time", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        case .sent:
            lblDate.textColor = ColorConfiguration.timeLabelTextColor
            ivStatus.tintColor = ColorConfiguration.timeLabelTextColor
            ivStatus.image = UIImage(named: "ic_sending", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)

            break
        case .delivered:
            lblDate.textColor = ColorConfiguration.timeLabelTextColor
            ivStatus.tintColor = ColorConfiguration.timeLabelTextColor
            ivStatus.image = UIImage(named: "ic_read", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        case .read:
            lblDate.textColor = ColorConfiguration.timeLabelTextColor
            ivStatus.tintColor = ColorConfiguration.readMessageColor
            ivStatus.image = UIImage(named: "ic_read", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        case . failed:
            lblDate.textColor = ColorConfiguration.failToSendColor
            lblDate.text = TextConfiguration.sharedInstance.failedText
            ivStatus.image = UIImage(named: "ic_warning", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            ivStatus.tintColor = ColorConfiguration.failToSendColor
            break
        case .deleting:
            //            ivStatus.image = UIImage(named: "ic_deleted", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            break
        }
    }
    
}
