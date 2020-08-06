//
//  QFileLeftCell.swift
//  BBChat
//
//  Created by qiscus on 24/01/20.
//

#if os(iOS)
import UIKit
#endif
import QiscusCore

class QFileLeftCell: UIBaseChatCell {

    @IBOutlet weak var lblExtension: UILabel!
    @IBOutlet weak var ivBubble: UIImageView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var ivIcon: UIImageView!
    @IBOutlet weak var lblFilename: UILabel!
    @IBOutlet weak var viewDownloadButtonContainer: UIView!
    
    var actionBlock: ((QMessage) -> Void)? = nil
    var downloadBlock: ((QMessage) -> Void)? = nil
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override func present(message: QMessage) {
        self.bind(message: message)
    }
    
    override func update(message: QMessage) {
        self.bind(message: message)
    }
    
    func bind(message: QMessage) {
        self.message = message
        self.setupBalon()
        guard let payload = message.payload else { return }
        self.lblDate.text = AppUtil.dateToHour(date: message.date())
        
        if !message.isMyComment() {
            self.ivIcon.image = UIImage(named: "ic_file_black", in: MultichannelWidget.bundle, compatibleWith: nil)
        }
        
        let url = payload["url"] as? String
        self.lblFilename.text = payload["file_name"] as? String
        self.lblExtension.text = ("\(message.fileExtension(fromURL: url!)) file")
    }
    
    @IBAction func downloadDidTap(_ sender: Any) {
        guard let message = self.message else {
            return
        }
        downloadBlock?(message)
    }
    
    @objc private func didTap() {
        guard let message = self.message else {
            return
        }
        
        self.actionBlock?(message)
    }
    
    func setupBalon() {
        self.ivBubble.applyShadow()
        self.ivBubble.image = self.getBallon()
        self.ivBubble.tintColor = ColorConfiguration.leftBubbleColor
        self.ivBubble.backgroundColor = ColorConfiguration.leftBubbleColor
        self.ivBubble.layer.cornerRadius = 5.0
        self.ivBubble.clipsToBounds = true

        self.lblFilename.textColor = ColorConfiguration.leftBubbleTextColor
        self.lblExtension.textColor = ColorConfiguration.leftBubbleTextColor
        self.lblDate.textColor = ColorConfiguration.timeLabelTextColor
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTap))
        self.ivBubble.addGestureRecognizer(tapGesture)
        self.ivBubble.isUserInteractionEnabled = true
    }
    
}
