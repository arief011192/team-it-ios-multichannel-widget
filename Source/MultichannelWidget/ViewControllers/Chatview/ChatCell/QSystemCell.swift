//
//  QSystemCell.swift
//  Qiscus
//
//  Created by asharijuang on 05/09/18.
//

#if os(iOS)
import UIKit
#endif

import QiscusCoreAPI

class QSystemCell:  UIBaseChatCell {
    
    @IBOutlet weak var lbComment: UILabel!
    @IBOutlet weak var ivBackground: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func present(message: CommentModel) {
        // parsing payload
        self.bindData(message: message)
        
    }
    
    override func update(message: CommentModel) {
        self.bindData(message: message)
    }
    
    func bindData(message: CommentModel){
        setupBalon()
        lbComment.text = message.message
    }
    
    func setupBalon() {
        self.ivBackground.layer.cornerRadius = 5.0
        self.ivBackground.clipsToBounds = true
    }
    
    
}
