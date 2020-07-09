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
import QiscusCoreAPI
import Alamofire
import AlamofireImage
import SwiftyJSON

enum QUploaderType {
    case image
    case video
}

class QiscusUploaderVC: UIViewController, UIScrollViewDelegate,UITextViewDelegate {

    @IBOutlet weak var heightProgressViewCons: NSLayoutConstraint!
    @IBOutlet weak var labelProgress: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var containerProgressView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var inputBottom: NSLayoutConstraint!
    @IBOutlet weak var mediaCaption: UITextView!
    @IBOutlet weak var minInputHeight: NSLayoutConstraint!
    
    
    var chatView:UIChatViewController?
    var type = QUploaderType.image
    var data   : Data?
    var fileName :String?
    var imageData: [CommentModel] = []
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
            
            guard let token = QismoManager.shared.qiscus.userProfile?.token else { return }
            
            let header: HTTPHeaders = [
                "Content-Type": "application/json",
                "QISCUS_SDK_APP_ID": "\(QismoManager.shared.qiscus.config.appId)",
                "QISCUS_SDK_TOKEN" : "\(token)"
            ]

            AF.upload(multipartFormData: { (multipartFormData) in
                multipartFormData.append(self.data!, withName: "file", fileName: self.fileName!, mimeType: "image/jpg")
            }, to: "\(QismoManager.shared.qiscus.config.server.url)/upload", method: .post, headers: header, interceptor: nil).uploadProgress { [weak self] (progress) in
                guard let self = self else {
                    return
                }
                print(progress.fractionCompleted)
                self.showProgress()
                self.labelProgress.text = "\(Int(progress.fractionCompleted * 100)) %"
                let newHeight = progress.fractionCompleted * self.maxProgressHeight
                self.heightProgressViewCons.constant = CGFloat(newHeight)
                UIView.animate(withDuration: 0.65, animations: {
                    self.progressView.layoutIfNeeded()
                })
            }.responseJSON { response in
                switch response.result {
                case .success(_):
                    guard let jsonResponse = response.value as? [String: Any] else {return}
                    print(jsonResponse)
                    
                    let image = JSON(jsonResponse)

                    self.sendButton.isEnabled = true
                    self.sendButton.isHidden = false
                    self.hiddenProgress()
                    
                    let message = QismoManager.shared.qiscus.newMessage()
                    message.type = "file_attachment"
                    message.payload = [
                        "url"       : image["results"]["file"]["url"].stringValue,
                        "file_name" : file.name,
                        "size"      : image["results"]["file"]["size"].stringValue,
                        "caption"   : ""
                    ]
                    
                    message.message = "Send Image"
                    self.imageData.append(message)
                case .failure(let error):
                    print(error)
                }
            }
            
        }
        
        for gesture in self.view.gestureRecognizers! {
            self.view.removeGestureRecognizer(gesture)
        }
    }
    
    func setupUI(){
        self.title = "Image"
        self.hiddenProgress()
        self.containerProgressView.layer.cornerRadius = self.containerProgressView.frame.height / 2
        
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
        
        self.sendButton.isEnabled = false
        self.sendButton.isHidden = true

    }
    
    func hiddenProgress(){
        self.containerProgressView.isHidden = true
        self.labelProgress.isHidden = true
        self.progressView.isHidden = true
    }
    
    func showProgress(){
        self.labelProgress.isHidden = false
        self.containerProgressView.isHidden = false
        self.progressView.isHidden = false
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
                self.imageData.first?.payload![ "caption" ] = mediaCaption.text
            }
            
            chatView?.send(message: self.imageData.first!, onSuccess: { (comment) in
                self.chatView?.setFromUploader(comment: comment)
                let _ = self.navigationController?.popViewController(animated: true)
            }, onError: { (error) in
                let _ = self.navigationController?.popViewController(animated: true)
            })
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
        self.minInputHeight.constant = 32 * 3
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @IBAction func cancel(_ sender: Any) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
}

