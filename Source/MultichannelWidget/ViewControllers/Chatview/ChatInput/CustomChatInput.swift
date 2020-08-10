//
//  CustomChatInput.swift
//  Example
//
//  Created by Qiscus on 04/09/18.
//  Copyright © 2018 Qiscus. All rights reserved.
//

#if os(iOS)
import UIKit
#endif
import Photos
import MobileCoreServices
import QiscusCore
import SwiftyJSON
import Alamofire
import AlamofireImage

protocol CustomChatInputDelegate {
    func sendAttachment()
    func sendImageAttachment()
    func sendMessage(message: QMessage)
    func hideReply()
}

protocol ReplyChatInputDelegate {
    func hideReply()
}

class CustomChatInput: UIChatInput {
    
    @IBOutlet weak var heightView: NSLayoutConstraint!
    @IBOutlet weak var widthReplyImage: NSLayoutConstraint!
    
    @IBOutlet weak var imageThumb: UIImageView!
    @IBOutlet weak var viewReply: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    @IBOutlet weak var imageAttachmentButton: UIButton!
    @IBOutlet weak var contraintTopReply: NSLayoutConstraint!
    @IBOutlet weak var tvReply: UILabel!
    @IBOutlet weak var heightTextViewCons: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    var chatInputDelegate : CustomChatInputDelegate? = nil
    var replyChatInputDelegate: ReplyChatInputDelegate? = nil
    //    var defaultInputBarHeight: CGFloat = 34.0
    //    var customInputBarHeight: CGFloat = 34.0
    var colorName : UIColor = UIColor.black
    var replyComment: QMessage? = nil
    
    override func commonInit(nib: UINib) {
        let nib = UINib(nibName: "CustomChatInput", bundle: MultichannelWidget.bundle)
        super.commonInit(nib: nib)
        textView.delegate = self
        textView.text = TextConfiguration.sharedInstance.textPlaceholder
        textView.textColor = UIColor.lightGray
        textView.font = ChatConfig.chatFont
        textView.layer.borderColor = #colorLiteral(red: 0.9176470588, green: 0.9176470588, blue: 0.9137254902, alpha: 1)
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 2, left: 2, bottom: 0, right: 2)
        
        self.sendButton.tintColor = ColorConfiguration.sendButtonColor
        self.attachButton.tintColor = ColorConfiguration.attachmentButtonColor
        self.attachButton.setImage(UIImage(named: "ic_file_attachment", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.imageAttachmentButton.tintColor = ColorConfiguration.attachmentButtonColor
        self.imageAttachmentButton.setImage(UIImage(named: "ic_image_attachment", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.sendButton.setImage(UIImage(named: "ic_send", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    @IBAction func clickSend(_ sender: Any) {
        guard let text = self.textView.text else {return}
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text != TextConfiguration.sharedInstance.textPlaceholder {
            //            var payload:JSON? = nil
            let comment = QMessage()
            
            if let _replyData = replyComment {
                let senderName = _replyData.sender.name
                comment.type = "reply"
                comment.message = text
                comment.payload = [
                    "replied_comment_sender_email"       : _replyData.userEmail,
                    "replied_comment_id" : Int(_replyData.id) ?? 0,
                    "text"      : text,
                    "replied_comment_message"   : _replyData.message,
                    "replied_comment_sender_username" : senderName,
                    "replied_comment_payload" : _replyData.payload ?? [:],
                    "replied_comment_type" : _replyData.type
                ]
                self.replyComment = nil
            } else {
                comment.type = "text"
                comment.message = text
            }
            
            self.chatInputDelegate?.sendMessage(message: comment)
        }
        
        self.textView.text = ""
        self.setHeight(50)
        hideReply()
    }
    @IBAction func clickImageAttachment(_ sender: Any) {
        self.chatInputDelegate?.sendImageAttachment()
    }
    
    @IBAction func clickAttachment(_ sender: Any) {
        self.chatInputDelegate?.sendAttachment()
    }
    
    @IBAction func closeReply(_ sender: Any) {
        hideReply()
    }
    
    public func showReplyView(comment: QMessage) {
        self.contraintTopReply.constant = 0
        self.viewReply.isHidden = false
        self.tvReply.text = comment.message
        self.replyComment = comment
        if comment.isAttachment(text: comment.message) {
            self.widthReplyImage.constant = 40
            guard let url = URL(string: comment.getAttachmentURL(message: comment.message)) else { return }
            let ext = comment.fileExtension(fromURL: url.absoluteString)
            if(ext.contains("jpg") || ext.contains("png") || ext.contains("heic") || ext.contains("jpeg") || ext.contains("tif") || ext.contains("gif")) {
                self.imageThumb.af.setImage(withURL: url)
            }else {
                self.imageThumb.image = UIImage(named: "ic_file_black", in: MultichannelWidget.bundle, compatibleWith: nil)
            }
            
            if let payload = comment.payload, let caption = payload["caption"] as? String, !caption.isEmpty {
                self.tvReply.text = caption
            }else {
                self.tvReply.text = "File Attachment"
            }
        }else {
            self.widthReplyImage.constant = 0
        }
    }
    
    public func hideReply() {
        self.contraintTopReply.constant = -50
        self.viewReply.isHidden = true
        self.replyChatInputDelegate?.hideReply()
        self.replyComment = nil
    }
    
}

extension CustomChatInput : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if(textView.text == TextConfiguration.sharedInstance.textPlaceholder){
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if(textView.text.isEmpty){
            textView.text = TextConfiguration.sharedInstance.textPlaceholder
            textView.textColor = UIColor.lightGray
        }
        self.typing(false)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.typing(true)
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize.init(width: fixedWidth, height: CGFloat(MAXFLOAT)))
        if (newSize.height <= 100) {
            self.heightTextViewCons.constant = newSize.height + 10
            self.heightView.constant = newSize.height + 25.0
            if self.replyComment != nil {
                self.setHeight(self.heightView.constant + 50)
            } else {
                self.setHeight(self.heightView.constant)
            }
        } else {
            self.heightTextViewCons.constant = 100 + 10
            self.heightView.constant = 100   + 25.0
            if self.replyComment != nil {
                self.setHeight(self.heightView.constant + 50)
            } else {
                self.setHeight(self.heightView.constant)
            }
        }
        
        if (newSize.height >= 100) {
            self.textView.isScrollEnabled = true
        }
        
        if textView.text.isEmpty {
            self.typing(false)
        }
    }
}

extension UIChatViewController : CustomChatInputDelegate {
    func uploadCamera() {
        self.view.endEditing(true)
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized
        {
            DispatchQueue.main.async(execute: {
                if #available(iOS 11.0, *) {
                    self.latestNavbarTint = self.currentNavbarTint
                    UINavigationBar.appearance().tintColor = UIColor.blue
                }
                
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.allowsEditing = false
                picker.mediaTypes = [(kUTTypeImage as String)]
                
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            })
        }else{
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted :Bool) -> Void in
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    if granted {
                        PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
                            switch status{
                            case .authorized:
                                DispatchQueue.main.async(execute: {
                                    if #available(iOS 11.0, *) {
                                        self.latestNavbarTint = self.currentNavbarTint
                                        UINavigationBar.appearance().tintColor = UIColor.blue
                                    }
                                    let picker = UIImagePickerController()
                                    picker.delegate = self
                                    picker.allowsEditing = false
                                    picker.mediaTypes = [(kUTTypeImage as String)]
                                    
                                    picker.sourceType = .camera
                                    self.present(picker, animated: true, completion: nil)
                                })
                                break
                            case .denied:
                                self.showPhotoAccessAlert()
                                break
                            default:
                                self.showPhotoAccessAlert()
                                break
                            }
                        })
                    }else{
                        DispatchQueue.main.async(execute: {
                            self.showCameraAccessAlert()
                        })
                    }
                }else{
                    //no camera
                }
                
            })
        }
    }
    
    func uploadGalery() {
        self.view.endEditing(true)
        let photoPermissions = PHPhotoLibrary.authorizationStatus()
        
        if(photoPermissions == PHAuthorizationStatus.authorized){
            self.goToGaleryPicker()
        }else if(photoPermissions == PHAuthorizationStatus.notDetermined){
            PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
                switch status{
                case .authorized:
                    self.goToGaleryPicker()
                    break
                case .denied:
                    self.showPhotoAccessAlert()
                    break
                default:
                    self.showPhotoAccessAlert()
                    break
                }
            })
        }else{
            self.showPhotoAccessAlert()
        }
    }
    
    func uploadFile(){
        if #available(iOS 11.0, *) {
            self.latestNavbarTint = self.currentNavbarTint
            UINavigationBar.appearance().tintColor = UIColor.blue
        }
        
        let documentPicker = UIDocumentPickerViewController(documentTypes: self.UTIs, in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .fullScreen
        
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func goToGaleryPicker(){
        DispatchQueue.main.async(execute: {
            if #available(iOS 11.0, *) {
                self.latestNavbarTint = self.currentNavbarTint
                UINavigationBar.appearance().tintColor = UIColor.blue
            }
            
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = false
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary
            picker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
            self.present(picker, animated: true, completion: nil)
        })
    }
    
    func showPhotoAccessAlert(){
        DispatchQueue.main.async(execute: {
            let text = TextConfiguration.sharedInstance.galeryAccessAlertText
            let cancelTxt = TextConfiguration.sharedInstance.alertCancelText
            let settingTxt = TextConfiguration.sharedInstance.alertSettingText
            QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: settingTxt, secondActionTitle: cancelTxt,
                                 doneAction: {
                                    self.goToIPhoneSetting()
            },
                                 cancelAction: {}
            )
        })
    }
    
    //Alert
    func goToIPhoneSetting(){
        UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func showCameraAccessAlert(){
        DispatchQueue.main.async(execute: {
            let text = TextConfiguration.sharedInstance.cameraAccessAlertText
            let cancelTxt = TextConfiguration.sharedInstance.alertCancelText
            let settingTxt = TextConfiguration.sharedInstance.alertSettingText
            QPopUpView.showAlert(withTarget: self, message: text, firstActionTitle: settingTxt, secondActionTitle: cancelTxt,
                                 doneAction: {
                                    self.goToIPhoneSetting()
            },
                                 cancelAction: {}
            )
        })
    }
    
    func sendMessage(message: QMessage) {
        let postedComment = message
        
        self.send(message: postedComment, onSuccess: { (comment) in
            //success
        }) { (error) in
            //error
        }
    }
    
    func sendImageAttachment() {
        let optionMenu = UIAlertController()
        let cameraAction = UIAlertAction(title: "Take Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.uploadCamera()
        })
        optionMenu.addAction(cameraAction)
        
        
        let galleryAction = UIAlertAction(title: "Image from Gallery", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.uploadGalery()
        })
        optionMenu.addAction(galleryAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            
        })
        
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func sendAttachment() {
        self.uploadFile()
    }
    
}

// MARK: - UIDocumentPickerDelegate
extension UIChatViewController: UIDocumentPickerDelegate{
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().tintColor = self.latestNavbarTint
            self.navigationController?.navigationBar.tintColor = self.latestNavbarTint
        }
        self.postReceivedFile(fileUrl: url)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().tintColor = self.latestNavbarTint
            self.navigationController?.navigationBar.tintColor = self.latestNavbarTint
        }
    }
    
    public func postReceivedFile(fileUrl: URL) {
        // guard let token = QismoManager.shared.network.qiscusUser?.token else { return }
        var contentPayload: [String: Any] = [:]
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: fileUrl, options: NSFileCoordinator.ReadingOptions.forUploading, error: nil) { (dataURL) in
            do{
                var data:Data = try Data(contentsOf: dataURL, options: NSData.ReadingOptions.mappedIfSafe)
                let mediaSize = Double(data.count) / 1024.0
                
                if mediaSize > self.maxUploadSizeInKB {
                    self.showFileTooBigAlert()
                    return
                }
                
                var fileName = dataURL.lastPathComponent.replacingOccurrences(of: "%20", with: "_")
                fileName = fileName.replacingOccurrences(of: " ", with: "_")
                
                var popupText = TextConfiguration.sharedInstance.confirmationImageUploadText
                var fileType = QiscusFileType.image
                var thumb:UIImage? = nil
                let fileNameArr = (fileName as String).split(separator: ".")
                let ext = String(fileNameArr.last!).lowercased()
                
                let gif = (ext == "gif" || ext == "gif_")
                let video = (ext == "mp4" || ext == "mp4_" || ext == "mov" || ext == "mov_")
                let isImage = (ext == "jpg" || ext == "jpg_" || ext == "tif" || ext == "heic" || ext == "png" || ext == "png_")
                let isPDF = (ext == "pdf" || ext == "pdf_")
                var usePopup = false
                
                if isImage{
                    var i = 0
                    for n in fileNameArr{
                        if i == 0 {
                            fileName = String(n)
                        }else if i == fileNameArr.count - 1 {
                            fileName = "\(fileName).jpg"
                        }else{
                            fileName = "\(fileName).\(String(n))"
                        }
                        i += 1
                    }
                    let image = UIImage(data: data)!
                    let imageSize = image.size
                    var bigPart = CGFloat(0)
                    if(imageSize.width > imageSize.height){
                        bigPart = imageSize.width
                    }else{
                        bigPart = imageSize.height
                    }
                    
                    var compressVal = CGFloat(1)
                    if(bigPart > 2000){
                        compressVal = 2000 / bigPart
                    }
                    data = image.jpegData(compressionQuality:compressVal)!
                    thumb = UIImage(data: data)
                }else if isPDF{
                    usePopup = true
                    popupText = "Are you sure to send this document?"
                    fileType = QiscusFileType.document
                    if let provider = CGDataProvider(data: data as NSData) {
                        if let pdfDoc = CGPDFDocument(provider) {
                            if let pdfPage:CGPDFPage = pdfDoc.page(at: 1) {
                                var pageRect:CGRect = pdfPage.getBoxRect(.mediaBox)
                                pageRect.size = CGSize(width:pageRect.size.width, height:pageRect.size.height)
                                UIGraphicsBeginImageContext(pageRect.size)
                                if let context:CGContext = UIGraphicsGetCurrentContext(){
                                    context.saveGState()
                                    context.translateBy(x: 0.0, y: pageRect.size.height)
                                    context.scaleBy(x: 1.0, y: -1.0)
                                    context.concatenate(pdfPage.getDrawingTransform(.mediaBox, rect: pageRect, rotate: 0, preserveAspectRatio: true))
                                    context.drawPDFPage(pdfPage)
                                    context.restoreGState()
                                    if let pdfImage:UIImage = UIGraphicsGetImageFromCurrentImageContext() {
                                        thumb = pdfImage
                                    }
                                }
                                UIGraphicsEndImageContext()
                            }
                        }
                    }
                }
                else if gif{
                    let image = UIImage(data: data)!
                    thumb = image
                    let asset = PHAsset.fetchAssets(withALAssetURLs: [dataURL], options: nil)
                    if let phAsset = asset.firstObject {
                        let option = PHImageRequestOptions()
                        option.isSynchronous = true
                        option.isNetworkAccessAllowed = true
                        PHImageManager.default().requestImageData(for: phAsset, options: option) {
                            (gifData, dataURI, orientation, info) -> Void in
                            data = gifData!
                        }
                    }
                    popupText = "Are you sure to send this image?"
                    usePopup = true
                }else if video {
                    fileType = .video
                    
                    let assetMedia = AVURLAsset(url: dataURL)
                    let thumbGenerator = AVAssetImageGenerator(asset: assetMedia)
                    thumbGenerator.appliesPreferredTrackTransform = true
                    
                    let thumbTime = CMTimeMakeWithSeconds(0, preferredTimescale: 30)
                    let maxSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
                    thumbGenerator.maximumSize = maxSize
                    
                    do{
                        let thumbRef = try thumbGenerator.copyCGImage(at: thumbTime, actualTime: nil)
                        thumb = UIImage(cgImage: thumbRef)
                        popupText = "Are you sure to send this video?"
                    }catch{
                        print("error creating thumb image")
                    }
                    usePopup = true
                }else{
                    usePopup = true
                    let textFirst = TextConfiguration.sharedInstance.confirmationFileUploadText
                    let textMiddle = "\(fileName as String)"
                    let textLast = TextConfiguration.sharedInstance.questionMark
                    popupText = "\(textFirst) \(textMiddle) \(textLast)"
                    fileType = QiscusFileType.file
                }
                
                if usePopup {
                    QPopUpView.showAlert(withTarget: self, image: thumb, message:popupText, isVideoImage: video,
                                         doneAction: {
                                            
                                            let fileModel = FileUploadModel()
                                            fileModel.name = fileName
                                            fileModel.data = data
                                            QismoManager.shared.qiscus.shared.upload(file: fileModel, onSuccess: { [weak self] (fileModel) in
                                                
                                                let message = QMessage()
                                                message.type = "file_attachment"
                                                message.payload = [
                                                    "url"       : fileModel.url.absoluteString,
                                                    "file_name" : fileModel.name,
                                                    "size"      : fileModel.size,
                                                    "caption"   : ""
                                                ]
                                                
                                                message.message = "Send Attachment"
                                                self?.send(message: message, onSuccess: { (comment) in
                                                    debugPrint(message)
                                                }, onError: { (error) in
                                                    self?.heightProgressBar.constant = 0
                                                    self?.widthProgress.constant = 0
                                                })
                                                }, onError: { (error) in
                                                    print(error)
                                            }) { [weak self] (progress) in
                                                guard let self = self else {
                                                    return
                                                }
                                                self.heightProgressBar.constant = 10
                                                self.widthProgress.constant = CGFloat(progress) * UIScreen.main.bounds.width
                                                print("upload progress :\(progress) isMainThread \(Thread.isMainThread)")
                                                
                                                if(progress == 1) {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                        self.heightProgressBar.constant = 0
                                                        self.widthProgress.constant = 0
                                                    }
                                                }
                                            }
                                            
                    },
                                         cancelAction: {
                                            
                    })
                } else {
                    let fileUploadModel = FileUploadModel()
                    fileUploadModel.name = fileName
                    fileUploadModel.data = data
                    
                    QismoManager.shared.qiscus.shared.upload(file: fileUploadModel, onSuccess: { [weak self] (fileModel) in
                        let message = QMessage()
                        message.type = "file_attachment"
                        message.payload = [
                            "url"       : fileModel.url.absoluteString,
                            "file_name" : fileModel.name,
                            "size"      : fileModel.size,
                            "caption"   : ""
                        ]
                        
                        message.message = "Send Attachment"
                        self?.send(message: message, onSuccess: { (comment) in
                            debugPrint(message)
                        }, onError: { (error) in
                            self?.heightProgressBar.constant = 0
                            self?.widthProgress.constant = 0
                        })
                        }, onError: { (error) in
                            print(error)
                    }) { [weak self] (progress) in
                        guard let self = self else {
                            return
                        }
                        print("upload progress :\(progress)")
                        self.heightProgressBar.constant = 10
                        self.widthProgress.constant = CGFloat(progress) * UIScreen.main.bounds.width
                        print("upload progress :\(progress) isMainThread \(Thread.isMainThread)")
                        
                        if(progress == 1) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                self.heightProgressBar.constant = 0
                                self.widthProgress.constant = 0
                            }
                        }
                    }
                }
                
            } catch _{
                //finish loading
                //self.dismissLoading()
                
            }
        }
    }
}

// Image Picker
extension UIChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func showFileTooBigAlert(){
        let alertController = UIAlertController(title: "Fail to upload", message: "File too big", preferredStyle: .alert)
        let galeryActionButton = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in }
        alertController.addAction(galeryActionButton)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().tintColor = self.latestNavbarTint
            self.navigationController?.navigationBar.tintColor = self.latestNavbarTint
        }
        
        let fileType:String = info[.mediaType] as! String
        let time = Double(Date().timeIntervalSince1970)
        let timeToken = UInt64(time * 10000)
        
        if fileType == "public.image"{
            
            var imageName:String = "\(NSDate().timeIntervalSince1970 * 1000).jpg"
            let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            var data = image.pngData()
            
            if let imageURL = info[UIImagePickerController.InfoKey.referenceURL] as? URL{
                imageName = imageURL.lastPathComponent
                
                let imageNameArr = imageName.split(separator: ".")
                let imageExt:String = String(imageNameArr.last!).lowercased()
                
                let gif:Bool = (imageExt == "gif" || imageExt == "gif_")
                let png:Bool = (imageExt == "png" || imageExt == "png_")
                
                if png{
                    data = image.pngData()!
                }else if gif{
                    let asset = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
                    if let phAsset = asset.firstObject {
                        let option = PHImageRequestOptions()
                        option.isSynchronous = true
                        option.isNetworkAccessAllowed = true
                        PHImageManager.default().requestImageData(for: phAsset, options: option) {
                            (gifData, dataURI, orientation, info) -> Void in
                            data = gifData
                        }
                    }
                }else{
                    let result = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
                    let asset = result.firstObject
                    imageName = "\((asset?.value(forKey: "filename"))!)"
                    imageName = imageName.replacingOccurrences(of: "HEIC", with: "jpg")
                    let imageSize = image.size
                    var bigPart = CGFloat(0)
                    if(imageSize.width > imageSize.height){
                        bigPart = imageSize.width
                    }else{
                        bigPart = imageSize.height
                    }
                    
                    var compressVal = CGFloat(1)
                    if(bigPart > 2000){
                        compressVal = 2000 / bigPart
                    }
                    
                    data = image.jpegData(compressionQuality:compressVal)
                }
            }else{
                let imageSize = image.size
                var bigPart = CGFloat(0)
                if(imageSize.width > imageSize.height){
                    bigPart = imageSize.width
                }else{
                    bigPart = imageSize.height
                }
                
                var compressVal = CGFloat(1)
                if(bigPart > 2000){
                    compressVal = 2000 / bigPart
                }
                
                data = image.jpegData(compressionQuality:compressVal)
            }
            
            if data != nil {
                let mediaSize = Double(data!.count) / 1024.0
                if mediaSize > self.maxUploadSizeInKB {
                    picker.dismiss(animated: true, completion: {
                        self.showFileTooBigAlert()
                    })
                    return
                }
                
                dismiss(animated:true, completion: nil)
                
                let uploader = QiscusUploaderVC()
                uploader.chatView = self
                uploader.data = data
                uploader.fileName = imageName
                self.navigationController?.pushViewController(uploader, animated: true)
                picker.dismiss(animated: true, completion: {
                    
                })
                
                
            }
            
        }else if fileType == "public.movie" {
            let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as! URL
            let fileName = mediaURL.lastPathComponent
            
            let mediaData = try? Data(contentsOf: mediaURL)
            let mediaSize = Double(mediaData!.count) / 1024.0
            if mediaSize > self.maxUploadSizeInKB {
                picker.dismiss(animated: true, completion: {
                    self.showFileTooBigAlert()
                })
                return
            }
            //create thumb image
            let assetMedia = AVURLAsset(url: mediaURL)
            let thumbGenerator = AVAssetImageGenerator(asset: assetMedia)
            thumbGenerator.appliesPreferredTrackTransform = true
            
            let thumbTime = CMTimeMakeWithSeconds(0, preferredTimescale: 30)
            let maxSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
            thumbGenerator.maximumSize = maxSize
            
            picker.dismiss(animated: true, completion: {
                
            })
            do{
                let thumbRef = try thumbGenerator.copyCGImage(at: thumbTime, actualTime: nil)
                let thumbImage = UIImage(cgImage: thumbRef)
                
                QPopUpView.showAlert(withTarget: self, image: thumbImage, message:"Are you sure to send this video?", isVideoImage: true,
                                     doneAction: {

                                        let fileModel = FileUploadModel()
                                        fileModel.name = fileName
                                        fileModel.data = mediaData!
                                        QismoManager.shared.qiscus.shared.upload(file: fileModel, onSuccess: { [weak self] (fileModel) in
                                            
                                            let message = QMessage()
                                            message.type = "file_attachment"
                                            message.payload = [
                                                "url"       : fileModel.url.absoluteString,
                                                "file_name" : fileModel.name,
                                                "size"      : fileModel.size,
                                                "caption"   : ""
                                            ]
                                            
                                            message.message = "Send Attachment"
                                            self?.send(message: message, onSuccess: { (comment) in
                                                debugPrint(message)
                                            }, onError: { (error) in
                                                self?.heightProgressBar.constant = 0
                                                self?.widthProgress.constant = 0
                                            })
                                            }, onError: { (error) in
                                                print(error)
                                        }) { [weak self] (progress) in
                                            guard let self = self else {
                                                return
                                            }
                                            self.heightProgressBar.constant = 10
                                            self.widthProgress.constant = CGFloat(progress) * UIScreen.main.bounds.width
                                            print("upload progress :\(progress) isMainThread \(Thread.isMainThread)")
                                            
                                            if(progress == 1) {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                    self.heightProgressBar.constant = 0
                                                    self.widthProgress.constant = 0
                                                }
                                            }
                                        }
                },
                                     cancelAction: {
                                        //cancel upload
                }
                )
            }catch{
                print("error creating thumb image")
            }
        }
        
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().tintColor = self.latestNavbarTint
            self.navigationController?.navigationBar.tintColor = self.latestNavbarTint
        }
        dismiss(animated: true, completion: nil)
    }
}
