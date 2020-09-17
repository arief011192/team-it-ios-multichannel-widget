//
//  QImagesLeftCell.swift
//  BBChat
//
//  Created by qiscus on 13/01/20.
//

#if os(iOS)
import UIKit
#endif
import QiscusCore
import Alamofire
import AlamofireImage

class QImagesLeftCell: UIBaseChatCell {
    
    @IBOutlet weak var lblCaption: UILabel!
    @IBOutlet weak var ivLeftBubble: UIImageView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var ivComment: UIImageView!
    @IBOutlet weak var marginCommentTop: NSLayoutConstraint!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var isPublic: Bool = false
    var menuConfig = enableMenuConfig()
    var colorName : UIColor = UIColor.black
    
    var actionBlock: ((QMessage) -> Void)? = nil
    var imageRequest: DownloadRequest? = nil
    
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
    
    override func present(message: QMessage) {
        self.bindData(message: message)
    }
    
    override func update(message: QMessage) {
        self.bindData(message: message)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageRequest?.cancel()
        self.ivComment.image = nil
        self.marginCommentTop.constant = 7
        self.loadingIndicator.isHidden = false
        self.loadingIndicator.startAnimating()
    }
    
    private func getUrlFromMessage(message: String) -> URL? {
        let prefixRemoval = message.replacingOccurrences(of: "[file]", with: "")
        let suffixRemoval = prefixRemoval.replacingOccurrences(of: "[/file]", with: "")
        
        return URL(string: suffixRemoval.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func setupBalon(){
        self.ivLeftBubble.applyShadow()
        self.ivLeftBubble.image = self.getBallon()
        self.ivLeftBubble.tintColor = ColorConfiguration.leftBubbleColor
        self.ivLeftBubble.backgroundColor = ColorConfiguration.leftBubbleColor
        self.ivLeftBubble.layer.cornerRadius = 5.0
        self.ivLeftBubble.clipsToBounds = true
        self.ivComment.layer.cornerRadius = 5.0
        self.ivComment.contentMode = .scaleAspectFill
        self.ivComment.clipsToBounds = true
        
    }
    
    func bindData(message: QMessage) {
        setupBalon()
        self.lblDate.text = AppUtil.dateToHour(date: message.timestamp)
        self.lblDate.textColor = ColorConfiguration.timeLabelTextColor
        
        let caption = message.payload?["caption"] as? String
        
        if (caption ?? "").isEmpty {
            self.marginCommentTop.constant = -8
        }
        
        if caption != nil {
            self.lblCaption.text = caption
            self.lblCaption.isHidden = false
        } else {
            self.lblCaption.isHidden = true
        }
        
        var url = message.payload?["url"] as? String
        
        if url == nil {
            url = getUrlFromMessage(message: message.message)?.absoluteString
        }
        
        if let imageUrl = URL(string: url ?? "") {
            if let cachedImage = QismoManager.shared.imageCache.object(forKey: NSString(string: url ?? "")) {
                self.ivComment.image = cachedImage
                self.loadingIndicator.isHidden = true
                self.loadingIndicator.stopAnimating()
            } else {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    let request = URLRequest(url: imageUrl)
                    
                    self.imageRequest = AF.download(request).responseData { (response) in
                        guard let imageData = response.value, let image = UIImage(data: imageData) else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.ivComment.image = image
                            self.loadingIndicator.isHidden = true
                            self.loadingIndicator.stopAnimating()
                        }
                        QismoManager.shared.imageCache.setObject(image, forKey: (url as NSString?) ?? "")
                    }
                }
            }
        }
    }
    
    @objc func imageDidTap() {
        if self.comment != nil && self.actionBlock != nil {
            self.actionBlock!(comment!)
        }
    }
    
}
