//
//  CommentModel.swift
//  Alamofire
//
//  Created by asharijuang on 07/08/18.
//

import Foundation
import SwiftyJSON
import QiscusCore
import Alamofire

@objc enum QiscusFileType:Int{
    case image
    case video
    case audio
    case document
    case file
    case pdf
}

public enum QReplyType:Int{
    case text
    case image
    case video
    case audio
    case document
    case location
    case contact
    case file
    case other
}

@objc enum CommentModelType:Int {
    case text
    case image
    case video
    case audio
    case file
    case postback
    case account
    case reply
    case system
    case card
    case contact
    case location
    case custom
    case document
    case carousel
    
    static let all = [text.name(), image.name(), video.name(), audio.name(),file.name(),postback.name(),account.name(), reply.name(), system.name(), card.name(), contact.name(), location.name(), custom.name()]
    
    func name() -> String{
        switch self {
        case .text      : return "text"
        case .image     : return "image"
        case .video     : return "video"
        case .audio     : return "audio"
        case .file      : return "file"
        case .postback  : return "postback"
        case .account   : return "account"
        case .reply     : return "reply"
        case .system    : return "system"
        case .card      : return "card"
        case .contact   : return "contact_person"
        case .location  : return "location"
        case .custom    : return "custom"
        case .document  : return "document"
        case .carousel  : return "carousel"
        }
    }
    init(name:String) {
        switch name {
        case "text","button_postback_response"     : self = .text ; break
        case "image"            : self = .image ; break
        case "video"            : self = .video ; break
        case "audio"            : self = .audio ; break
        case "file"             : self = .file ; break
        case "postback"         : self = .postback ; break
        case "account"          : self = .account ; break
        case "reply"            : self = .reply ; break
        case "system"           : self = .system ; break
        case "card"             : self = .card ; break
        case "contact_person"   : self = .contact ; break
        case "location"         : self = .location; break
        case "document"         : self = .document; break
        case "carousel"         : self = .carousel; break
        default                 : self = .custom ; break
        }
    }
}

extension QMessage {
    
    func isMyComment() -> Bool {
        //change this later when user savevd on presisstance storage
        if let user = QismoManager.shared.qiscus.getProfile() {
            return userEmail == user.id
        }else {
            return false
        }
        
    }
    
    func date() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone      = TimeZone(abbreviation: "UTC")
        let date = formatter.date(from: self.timestampString)
        return date
    }
    
    func hour() -> String {
        guard let date = self.date() else {
            return "-"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone      = TimeZone.current
        let defaultTimeZoneStr = formatter.string(from: date);
        return defaultTimeZoneStr
    }
    
    func isAttachment(text:String) -> Bool {
        var check:Bool = false
        if(text.hasPrefix("[file]")){
            check = true
        }
        return check
    }
    func getAttachmentURL(message: String) -> String {
        let component1 = message.components(separatedBy: "[file]")
        let component2 = component1.last!.components(separatedBy: "[/file]")
        let mediaUrlString = component2.first?.trimmingCharacters(in: CharacterSet.whitespaces).replacingOccurrences(of: " ", with: "%20")
        return mediaUrlString!
    }
    
    func fileExtension(fromURL url:String) -> String{
        var ext = ""
        if url.range(of: ".") != nil{
            let fileNameArr = url.split(separator: ".")
            ext = String(fileNameArr.last!).lowercased()
            if ext.contains("?"){
                let newArr = ext.split(separator: "?")
                ext = String(newArr.first!).lowercased()
            }
        }
        return ext
    }
    
    func fileName(text:String) ->String{
        let url = getAttachmentURL(message: text)
        var fileName:String = ""
        
        let remoteURL = url.replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: "’", with: "%E2%80%99")
        
        if let mediaURL = URL(string: remoteURL) {
            fileName = mediaURL.lastPathComponent.replacingOccurrences(of: "%20", with: "_")
        }
        
        return fileName
    }
    
    var typeMessage: CommentModelType{
        get{
            return CommentModelType(rawValue: type.hashValue)!
        }
        
    }
    
    func encodeDictionary()->[AnyHashable : Any]{
        var data = [AnyHashable : Any]()
        
        data["qiscus_commentdata"] = true
        data["qiscus_uniqueId"] = self.uniqueId
        data["qiscus_id"] = self.id
        data["qiscus_roomId"] = self.chatRoomId
        data["qiscus_beforeId"] = self.previousMessageId
        data["qiscus_text"] = self.message
        data["qiscus_createdAt"] = self.unixTimestamp
        data["qiscus_senderEmail"] = self.userEmail
        data["qiscus_senderName"] = self.userId
        data["qiscus_statusRaw"] = self.status
        data["qiscus_typeRaw"] = self.type
        data["qiscus_data"] = self.payload
        
        return data
    }
    
    open func replyType(message:String)->QReplyType{
        if self.isAttachment(text: message){
            let url = getAttachmentURL(message: message)
            
            switch self.fileExtension(fromURL: url) {
            case "jpg","jpg_","png","png_","gif","gif_":
                return .image
            case "m4a","m4a_","aac","aac_","mp3","mp3_":
                return .audio
            case "mov","mov_","mp4","mp4_":
                return .video
            case "pdf","pdf_":
                return .document
            case "doc","docx","ppt","pptx","xls","xlsx","txt":
                return .file
            default:
                return .other
            }
        }else{
            return .text
        }
    }
    
    func getLocalFilePath() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        func localFilePath(for url: URL) -> URL {
            return documentsPath.appendingPathComponent("\(url.lastPathComponent)")
        }
        
        guard let commentFileUrlPath = URL(string: getAttachmentURL(message: self.message)) else {
            return nil
        }
            
        let url = localFilePath(for: commentFileUrlPath)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: url.path) {
            return url
        }else {
            return nil
        }
    }
    
    func isFileDownloaded() -> Bool {
        guard getLocalFilePath() != nil else {
            return false
        }
        
        return true
    }
    
    func download(from viewController: UIViewController? = nil, downloadProgress: @escaping ((Double) -> Void), completetionHandler: ((URL) -> Void)? = nil) {
        let urlString = self.getAttachmentURL(message: self.message)
        let url = URL(string: urlString)
        let fileName = String((url!.lastPathComponent)) as NSString
        // Create destination URL
        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationFileUrl = documentsUrl.appendingPathComponent("\(fileName)")
        
        func handleDownload(localUrlPath: URL) {
            do {
                try FileManager.default.copyItem(at: localUrlPath, to: destinationFileUrl)
                completetionHandler?(destinationFileUrl)
                do {
                    //Show UIActivityViewController to save the downloaded file
                    let contents  = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    for indexx in 0..<contents.count {
                        if contents[indexx].lastPathComponent == destinationFileUrl.lastPathComponent {
                            DispatchQueue.main.async {
                                let activityViewController = UIActivityViewController(activityItems: [contents[indexx]], applicationActivities: nil)
                                viewController?.present(activityViewController, animated: true, completion: nil)
                            }
                        }
                    }
                }
                catch (let err) {
                    print("error: \(err)")
                }
            } catch (let writeError) {
                completetionHandler?(destinationFileUrl)
                do {
                    //Show UIActivityViewController to save the downloaded file
                    let contents  = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    for indexx in 0..<contents.count {
                        if contents[indexx].lastPathComponent == destinationFileUrl.lastPathComponent {
                            DispatchQueue.main.async {
                                let activityViewController = UIActivityViewController(activityItems: [contents[indexx]], applicationActivities: nil)
                                viewController?.present(activityViewController, animated: true, completion: nil)
                            }
                            return
                        }
                    }
                }
                catch (let err) {
                    print("error: \(err)")
                }
            }
        }
        
        if self.isFileDownloaded(), let localUrlPath = self.getLocalFilePath() {
            handleDownload(localUrlPath: localUrlPath)
            downloadProgress(1)
        } else {
            AF.download(urlString).response(completionHandler: { (response) in
            if let tempLocalUrl = response.fileURL {
                // Success
                handleDownload(localUrlPath: tempLocalUrl)
            }
            }).downloadProgress(closure: { progress in
                downloadProgress(progress.fractionCompleted)
            })
        }
    }
    
}
