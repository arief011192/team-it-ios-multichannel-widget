//
//  QiscusUploaderVC.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/12/17.
//  Copyright © 2017 Ahmad Athaullah. All rights reserved.
//

#if os(iOS)
import UIKit
#endif
import Photos
import MobileCoreServices
import QiscusCore
import Alamofire
import AlamofireImage
import SwiftyJSON

enum QUploaderType {
    case image
    case video
}

class QiscusUploaderVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var viewProgressContainer: UIView!
    @IBOutlet weak var labelProgress: UILabel!
    @IBOutlet weak var viewProgress: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var constraintProgressWidth: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var inputBottom: NSLayoutConstraint!
    @IBOutlet weak var mediaCaption: UITextView!
    @IBOutlet weak var minInputHeight: NSLayoutConstraint!
    
    
    var chatView:UIChatViewController?
    var type = QUploaderType.image
    var data   : Data?
    var fileName :String?
    var imageData: [QMessage] = []
    var selectedImageIndex: Int = 0
    let maxProgressHeight:Double = 40.0
    var content: [String: Any] = [:]
    /**
     Setup maximum size when you send attachment inside chat view, example send video/image from galery. By default maximum size is unlimited.
     */
    var maxUploadSizeInKB:Double = Double(100) * Double(1024)
    
    init() {
          super.init(nibName: "QiscusUploaderVC", bundle: MultichannelWidget.bundle)
      }
      required init?(coder aDecoder: NSCoder) {
          fatalError("init(coder:) has not been implemented")
      }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.setupUI()
        
        if self.fileName != nil && self.data != nil && self.imageData.count == 0 {
            self.title = self.fileName!
            
            let file = FileUploadModel()
            file.data = data!
            file.name = fileName!
            
            QismoManager.shared.qiscus.shared.upload(file: file, onSuccess: { (file) in
                self.sendButton.isEnabled = true
                self.sendButton.isHidden = false
                self.hiddenProgress()
                
                let message = QMessage()
                message.type = "file_attachment"
                message.payload = [
                    "url"       : file.url.absoluteString,
                    "file_name" : file.name,
                    "size"      : file.size,
                    "caption"   : ""
                ]
                message.message = "Send Image"
                message.status = .pending
                message.userEmail = SharedPreferences.getQiscusAccount() ?? ""
                self.imageData.append(message)
            }, onError: { (error) in
                //error
            }, progressListener: { (progress) in
                print("upload progress: \(progress)")
                self.showProgress()
                self.labelProgress.text = "\(Int(progress * 100)) %"
                
                self.constraintProgressWidth.constant = UIScreen.main.bounds.width * CGFloat(progress)
                UIView.animate(withDuration: 0.65, animations: {
                    self.viewProgressContainer.layoutIfNeeded()
                })
            })
            
        }
        
        for gesture in self.view.gestureRecognizers! {
            self.view.removeGestureRecognizer(gesture)
        }
    }
    
    func setupUI(){
        self.title = "Image"
        self.hiddenProgress()
        
        let keyboardToolBar = UIToolbar()
        keyboardToolBar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem:
            UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem:
            UIBarButtonItem.SystemItem.done, target: self, action: #selector(self.doneClicked) )
        
        keyboardToolBar.setItems([flexibleSpace, doneButton], animated: true)
        
        mediaCaption.inputAccessoryView = keyboardToolBar
        
        mediaCaption.text = TextConfiguration.sharedInstance.captionPlaceholder
        mediaCaption.textColor = UIColor.lightGray
        mediaCaption.delegate = self
        
        self.qiscusAutoHideKeyboard()
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 4.0
        self.sendButton.tintColor = ColorConfiguration.topColor
        self.mediaCaption.font = ChatConfig.chatFont
        
        self.sendButton.setImage(UIImage(named: "ic_send", in: MultichannelWidget.bundle, compatibleWith: nil), for: .normal)
        self.sendButton.setImage(UIImage(named: "ic_uploading", in: MultichannelWidget.bundle, compatibleWith: nil), for: .disabled)
        self.sendButton.isEnabled = false

    }
    
    func hiddenProgress(){
        viewProgressContainer.isHidden = true
    }
    
    func showProgress(){
        viewProgressContainer.isHidden = false
    }
    
    @objc func doneClicked() {
        view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = TextConfiguration.sharedInstance.captionPlaceholder
            textView.textColor = UIColor.lightGray
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.topItem?.title = ""
        if self.data != nil {
            if type == .image {
                self.imageView.image = UIImage(data: self.data!)
            }
        }

        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(QiscusUploaderVC.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(QiscusUploaderVC.keyboardChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    @IBAction func sendMedia(_ sender: Any) {
        if type == .image {
            
            if (mediaCaption.text != TextConfiguration.sharedInstance.captionPlaceholder ){
                self.imageData.first?.payload!["caption"] = mediaCaption.text
            }
            
            let _ = self.navigationController?.popViewController(animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self = self else {
                    return
                }
                self.chatView?.send(message: self.imageData.first!, onSuccess: { (comment) in
                    self.chatView?.setFromUploader(comment: comment)
                }, onError: { (error) in
                    print("error send image \(error)")
                })
            }
        
        }
    }
    
    // MARK: - Keyboard Methode
    @objc func keyboardWillHide(_ notification: Notification){
        let info: NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        
        let animateDuration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        self.inputBottom.constant = 0
        self.minInputHeight.constant = 32
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.view.layoutIfNeeded()
            
        }, completion: nil)
    }
    @objc func keyboardChange(_ notification: Notification){
        let info:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardHeight: CGFloat = keyboardSize.height
        let animateDuration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        
        self.inputBottom.constant = keyboardHeight
//        self.minInputHeight.constant = 32 * 3
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @IBAction func cancel(_ sender: Any) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
}

extension QiscusUploaderVC : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        chatView?.typing(true)
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize.init(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        if (newSize.height >= 35 && newSize.height <= 100) {
            self.minInputHeight.constant = newSize.height
//            self.heightView.constant = newSize.height + 10.0
//            if self.replyComment != nil {
//                self.setHeight(self.heightView.constant + 50)
//            } else {
//                self.setHeight(self.heightView.constant)
//            }
        }
        
        if (newSize.height >= 100) {
            textView.isScrollEnabled = true
        }
    }
}
