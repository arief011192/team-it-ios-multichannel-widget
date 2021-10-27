//
//  File.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 07/05/18.
//

#if os(iOS)
import UIKit
#endif
import Foundation
import QiscusCore
import AlamofireImage
import SwiftyJSON

protocol UIChatUserInteraction {
    func sendMessage(withText text: String)
    func loadRoom(withId roomId: String)
    func loadComments(withID roomId: String)
    func loadMore()
    func getAvatarImage(section: Int, imageView: UIImageView)
    func getMessage(atIndexPath: IndexPath) -> QMessage
}

protocol UIChatViewDelegate {
    func onLoadRoomFinished(roomName: String, roomAvatarURL: URL?)
    func onLoadRoomFinished(room: QChatRoom)
    func onLoading(message: String)
    func onLoadMessageFinished()
    func onLoadMessageFailed(message: String)
    func onLoadMoreMesageFinished()
    func onReloadComment()
    func onSendingComment(comment: QMessage, newSection: Bool)
    func onSendMessageFinished(comment: QMessage)
    func onGotNewComment(newSection: Bool)
    func onUpdateComment(comment: QMessage, indexpath: IndexPath)
    func onUser(name: String, typing: Bool)
    func onUser(name: String, isOnline: Bool, message: String)
    func onRoomResolved(isResolved: Bool)
    func onClosingMessageReceived(url: String)
}

class UIChatPresenter: UIChatUserInteraction {
    private var viewPresenter: UIChatViewDelegate?
    var comments: [[QMessage]]
    var room: QChatRoom?
    var loadMoreAvailable: Bool = true
    var participants : [QParticipant] = [QParticipant]()
    var loadMoreDispatchGroup: DispatchGroup = DispatchGroup()
    var lastIdToLoad: String = ""
    var lastIdToSynch: String = ""
    var connectionCheckTimer: Timer?
    var isDisconnected = false
    
    var qiscus : QiscusCore {
        get {
            return QismoManager.shared.qiscus
        }
    }
    
    init() {
        self.comments = [[QMessage]]()
    }
    
    func attachView(view : UIChatViewDelegate){
        connectionCheckTimer?.invalidate()
        connectionCheckTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(checkConnection), userInfo: nil, repeats: true)
        viewPresenter = view
        if let room = self.room {
            
            //            self.qiscus.roomDelegate = self
            //            self.qiscus.activeChatRoom = room
            //            self.qiscus.shared.subscribeChatRoom(room)
            //
            //            guard let participants = room.participants else { return }
            //            for u in participants {
            //                self.qiscus.shared.subscribeUserOnlinePresence(userId: u.id)
            //            }
            
            self.loadRoom()
            self.loadComments(withID: room.id)
            viewPresenter?.onLoadRoomFinished(roomName: room.name, roomAvatarURL: room.avatarUrl)
            if let p = room.participants {
                self.participants = p
            }
        }
    }
    
    @objc func checkConnection() {
       if Connectivity.isInternetConnected {
            if isDisconnected {
               print("INTERNET CONNECTED")
                isDisconnected = false
                self.qiscus.connect()
                self.resendPendingComment()
            }
        } else {
           if !isDisconnected {
               isDisconnected = true
               print("NO INTERNET")
           }
        }
    }
    
    func detachView() {
        connectionCheckTimer?.invalidate()
        connectionCheckTimer = nil
        viewPresenter = nil
        //        if let room = self.room {
        //            room.delegate = nil
        //        }
    }
    
    func getMessage(atIndexPath: IndexPath) -> QMessage {
        let comment = comments[atIndexPath.section][atIndexPath.row]
        return comment
    }
    
    func resendPendingComment() {
        self.qiscus.connect()
        guard let comments = self.qiscus.database.message.find(status: .pending) else { return }
        comments.reversed().forEach { (c) in
            // validation comment prevent id
            if c.uniqueId.isEmpty { self.qiscus.database.message.evaluate(); return }
            self.qiscus.shared.sendMessage(message: c, onSuccess: { (response) in
                
            }, onError: { (error) in
                
            })
        }
    }
    
    func loadRoom(withId roomId: String) {
        // Show Loading
        self.viewPresenter?.onLoading(message: "Load Message...")
        
        self.qiscus.shared.getChatRoomWithMessages(roomId: roomId, onSuccess: { [weak self] (room,comments) in
            guard let instance = self else { return }
            instance.qiscus.roomDelegate = self
            instance.qiscus.activeChatRoom = room
            instance.qiscus.shared.subscribeChatRoom(room)
            instance.qiscus.connect(delegate: self)
            instance.qiscus.connectionDelegate = self
            guard let participants = room.participants else { return }
            for u in participants {
                instance.qiscus.shared.subscribeUserOnlinePresence(userId: u.id)
            }
            
            instance.room = room
            self?.room = room
            self?.isResolvedRoom(room :room)
            instance.viewPresenter?.onLoadRoomFinished(room: room)
            
            if comments.isEmpty {
                instance.viewPresenter?.onLoadMessageFailed(message: "No message here yet...")
                return
            }
            
            instance.loadComments(withID: room.id)
            if let localComments = self?.qiscus.database.message.find(roomId: room.id) {
                let nonDeletedComments = localComments.filter { (message) -> Bool in
                    if SharedPreferences.getDeletedCommentUniqueId()?.contains(message.uniqueId) ?? false {
                        return false
                    }
                    
                    if message.typeMessage == .system {
                        return ChatConfig.showSystemMessage
                    }
                    
                    return true
                }
                instance.comments = instance.groupingComments(nonDeletedComments)
            } else {
                instance.comments = instance.groupingComments(comments)
            }
            
            if let lastComment = room.lastComment {
                instance.qiscus.shared.markAsRead(roomId: lastComment.chatRoomId, commentId: lastComment.id)
            }
            
            instance.viewPresenter?.onLoadMessageFinished()
            self?.lastIdToLoad = String(self?.room?.id ?? "")
            self?.lastIdToSynch = String(comments[0].id)
            
            }, onError: { [weak self] error in
                guard let instance = self else { return }
                instance.viewPresenter?.onLoadMessageFailed(message: "No message here yet...")
                print("error load message \(error.message)")
        })
    }
    
    //check is room already resolved
    func isResolvedRoom(room: QChatRoom) {
        guard let options = room.extras else {
            return
        }
        
        SharedPreferences.saveExtras(extras: options)
        
        let param = JSON(parseJSON: options)
        let isResolve = param["is_resolved"].boolValue
        viewPresenter?.onRoomResolved(isResolved: isResolve)
    }
    
    //check is closing message (message after resolved)
    func isClosingMessage(message : QMessage) {
        let extras = message.extras
        if extras?.count == 0 {
            return
        }
        if let url = extras!["survey_link"] as? String {
            viewPresenter?.onClosingMessageReceived(url: url)
            viewPresenter?.onRoomResolved(isResolved: true)
        }
        
    }
    
    /// Update room
    func loadRoom() {
        guard let _room = self.room else { return }
        self.loadRoom(withId: _room.id)
        //        QiscusCoreAPI.shared.getChatRoomWithMessages(roomId: _room.id, onSuccess: { [weak self] (room,comments) in
        //            guard let instance = self else { return }
        //            if comments.isEmpty {
        //                instance.viewPresenter?.onLoadMessageFailed(message: "no message")
        //                return
        //            }
        //            instance.loadComments(withID: room.id)
        //        }) { [weak self] (error) in
        //            guard let instance = self else { return }
        //            instance.viewPresenter?.onLoadMessageFailed(message: error.message)
        //        }
        
    }
    
    func loadComments(withID roomId: String) {
        //        if let room = QiscusCoreAPI.database.room.find(id: roomId){
        //            // load local
        //            if let _comments = QiscusCoreAPI.database.comment.find(roomId: roomId) {
        //                guard let lastComment = _comments.last else { return }
        //                // read comment
        //                if let lastComment = room.lastComment {
        //                     QiscusCoreAPI.shared.markAsRead(roomId: roomId, commentId: lastComment.id)
        //                }
        //
        //                self.comments = self.groupingComments(_comments)
        //                self.viewPresenter?.onLoadMessageFinished()
        //            }
        //        }
        
        
        
    }
    
    func syncMessage() {
        
        if lastIdToSynch.isEmpty { return }
        
        self.qiscus.synchronize(lastMessageId: lastIdToLoad, onSuccess: { [weak self] (comments) in
            guard let instance = self else { return }
            if comments.count == 0 {
                return
            }
            
            var temp: [QMessage] = []
            
            for msg in comments.reversed() {
                if (instance.getIndexPath(comment: msg) == nil) {
                    instance.addNewCommentUI(msg, isIncoming: true)
                    temp.append(msg)
                }
                if Int64(msg.id) ?? 0 > Int64(instance.lastIdToSynch) ?? 0 {
                    self?.lastIdToSynch = msg.id
                    
                }
                
                self?.isClosingMessage(message: msg)
            }
            
            if temp.count > 0 {
                instance.viewPresenter?.onLoadMoreMesageFinished()
            }
        }) { (error) in
            debugPrint(error.message)
        }
    }
    
    func loadMore() {
        if loadMoreAvailable {
            // initiate loadmore operation on background thread
            DispatchQueue.global(qos: .background).async { [weak self] in
                // since this is async we need to use weak rather than owned because we cant guarantee that self instance still exist, so we will use guard to avoid force unwraping optional value
                guard let instance = self else { return }
                
                // initiate loadmore dispatch group (as a queue to make it synchronous)
                instance.loadMoreDispatchGroup.enter()
                
                // avoiding on force unwrap optional value
                guard let lastGroup = instance.comments.last else { return }
                guard let lastComment = lastGroup.last else { return }
                //                guard let roomId = instance.room?.id else { return }
                //                guard let lastCommentId = Int(lastComment.id) else { return }
                
                // make sure that last comment's id isn't empty or load more for current id is still in process to prevent duplicate message
                if lastComment.id.isEmpty || instance.lastIdToLoad == lastComment.id {
                    return
                }
                
                // update lastIdToLoad value
                instance.lastIdToLoad = lastComment.id
                instance.qiscus.shared.loadMore(roomID: lastComment.chatRoomId, lastCommentID: lastComment.id, limit: 10, onSuccess: { (comments) in
                    instance.loadMoreDispatchGroup.leave()
                    
                    // if the loadmore from core return empty comment than it means that there are no comments left to be loaded anymore
                    if comments.count == 0 {
                        instance.loadMoreAvailable = false
                    }
                    
                    // we group the loaded comments by date(same day) and sender [[you, you][me, me][you]]
                    var groupedLoadedComment = instance.groupingComments(comments)
                    
                    // check if the first comment in the first section from the load more result has the same date then add merge first section from loaded comments with last section from existing comments
                    if lastComment.timestamp.reduceToMonthDayYear() == groupedLoadedComment.first?.first?.timestamp.reduceToMonthDayYear() {
                        // last section of existing comments
                        guard var lastGroup = instance.comments.last else { return }
                        
                        // first section of loaded comments
                        guard let firstGroupInLoadedComment = groupedLoadedComment.first else { return }
                        
                        // merge both of them
                        lastGroup.append(contentsOf: firstGroupInLoadedComment)
                        
                        // remove last section from existing comments
                        instance.comments.removeLast()
                        
                        // replace with merged comment (first section loaded comments and last section existing comment)
                        instance.comments.append(lastGroup)
                        
                        // remove section that has ben merged (first section) from the loaded comments
                        groupedLoadedComment.removeFirst()
                    }
                    
                    // finaly append the loaded comment from load more to existing comments
                    instance.comments.append(contentsOf: groupedLoadedComment)
                    
                    DispatchQueue.main.async {
                        // notify the ui that loadmore has completed
                        instance.viewPresenter?.onLoadMoreMesageFinished()
                    }
                }) { (error) in
                    debugPrint(error.message)
                }
                instance.loadMoreDispatchGroup.wait()
            }
        }
    }
    
    func isTyping(_ value: Bool) {
        if let r = self.room {
            self.qiscus.shared.publishTyping(roomID: r.id, isTyping: value)
        }
    }
    
    func sendMessage(withComment comment: QMessage, onSuccess: @escaping (QMessage) -> Void, onError: @escaping (String) -> Void) {
        addNewCommentUI(comment, isIncoming: false)
        self.qiscus.database.message.save([comment])
        self.qiscus.shared.sendMessage(message: comment, onSuccess: { [weak self] (comment) in
            guard let self = self else {
                return
            }
            
            for (group,c) in self.comments.enumerated() {
                if let index = c.index(where: { $0.uniqueId == comment.uniqueId }) {
                    self.comments[group][index] = comment
                    self.viewPresenter?.onUpdateComment(comment: comment, indexpath: IndexPath(row: index, section: group))
                }
            }
            //by default, lastId is empty...and keep like that if you not update after send first msg :)
            self.lastIdToSynch = comment.id
            onSuccess(comment)
        }) { (qError) in
            debugPrint(qError.message)
            onError(qError.message)
        }
    }
    
    func sendMessage(withText text: String) {
        // create object comment
        // MARK: TODO improve object generator
        
        let message = QMessage()
        message.message = text
        message.type    = "text"
        if let r = self.room {
            message.chatRoomId  = r.id
        }
        
        addNewCommentUI(message, isIncoming: false)
        //        QiscusCoreAPI.shared.sendMessage(message: message, onSuccess:{ [weak self] (comment) in
        //            self?.didComment(comment: comment, changeStatus: comment.status)
        //        }) { (error) in
        //            //
        //        }
    }
    
    private func addNewCommentUI(_ message: QMessage, isIncoming: Bool) {
        // Check first, if the message already deleted
        if message.typeMessage == .system && !ChatConfig.showSystemMessage {
            return
        }
        
        if SharedPreferences.getDeletedCommentUniqueId()?.contains(message.uniqueId) ?? false {
            return
        }
        
        // add new comment to ui
        var section = false
        if self.comments.count > 0 {
            if self.comments[0].count > 0 {
                let lastComment = self.comments[0][0]
                if lastComment.timestamp.reduceToMonthDayYear() == message.timestamp.reduceToMonthDayYear() {
                    self.comments[0].insert(message, at: 0)
                    section = false
                } else {
                    self.comments.insert([message], at: 0)
                    section = true
                }
            } else {
                self.comments.insert([message], at: 0)
                section = true
            }
        } else {
            // last comments is empty, then create new group and append this comment
            self.comments.insert([message], at: 0)
            section = true
        }
        
        // choose uidelegate
        if isIncoming {
            if self.viewPresenter != nil {
                QismoManager.shared.qiscus.shared.markAsRead(roomId: message.chatRoomId, commentId: message.id)
            }
            self.viewPresenter?.onGotNewComment(newSection: section)
        } else {
            self.viewPresenter?.onSendingComment(comment: message, newSection: section)
        }
    }
    
    func getAvatarImage(section: Int, imageView: UIImageView) {
        if self.comments.count > 0 {
            if self.comments[0].count > 0 {
                if let url = self.comments[0][0].userAvatarUrl {
                    imageView.af.setImage(withURL: url)
                }
            }
        }
    }
    
    /// Grouping by useremail and date(same day), example [[you,you],[me,me],[me]]
    private func groupingComments(_ data: [QMessage]) -> [[QMessage]]{
        var retVal = [[QMessage]]()
        let groupedMessages = Dictionary(grouping: data) { (element) -> Date in
            return element.timestamp.reduceToMonthDayYear()
        }
        
        let sortedKeys = groupedMessages.keys.sorted(by: { $0.compare($1) == .orderedDescending })
        sortedKeys.forEach { (key) in
            let values = groupedMessages[key]
            retVal.append(values ?? [])
        }
        return retVal
    }
    
    func getIndexPath(comment : QMessage) -> IndexPath? {
        for (group,c) in self.comments.enumerated() {
            if let index = c.index(where: { $0.uniqueId == comment.uniqueId }) {
                return IndexPath.init(row: index, section: group)
            }
        }
        return nil
    }
    
    func deleteMessage(comment: QMessage) {
        self.qiscus.shared.deleteMessages(messageUniqueIds: [comment.uniqueId], onSuccess: { [weak self] (comments) in
            SharedPreferences.saveDeletedComment(uniqueId: comment.uniqueId)
            self?.onMessageDeleted(message: comment)
        }) { (error) in
            
        }
    }
}


// MARK: Core Delegate
extension UIChatPresenter : QiscusCoreRoomDelegate {
    func onMessageUpdated(message: QMessage) {
        
    }
    
    func onUserOnlinePresence(userId: String, isOnline: Bool, lastSeen: Date) {
        debugPrint(userId)
    }
    
    func onMessageReceived(message: QMessage){
        
        if SharedPreferences.getDeletedCommentUniqueId()?.contains(message.uniqueId) ?? false {
            return
        }
        
        
        // 2check comment already in ui?
        if (self.getIndexPath(comment: message) == nil) {
            self.addNewCommentUI(message, isIncoming: true)
        }
        
        if message.type == "system_event" && message.message.lowercased().contains("admin marked this conversation as resolved") {
            viewPresenter?.onRoomResolved(isResolved: true)
        }
    }
    
    func onMessageDelivered(message : QMessage){
        if SharedPreferences.getDeletedCommentUniqueId()?.contains(message.uniqueId) ?? false {
            return
        }
        
        // check comment already exist in view
        for (group,c) in self.comments.enumerated() {
            if let index = c.index(where: { $0.uniqueId == message.uniqueId }) {
                self.comments[group][index] = message
                
                self.viewPresenter?.onUpdateComment(comment: message, indexpath: IndexPath(row: index, section: group))
            }
        }
    }
    
    func onMessageRead(message : QMessage){
        if SharedPreferences.getDeletedCommentUniqueId()?.contains(message.uniqueId) ?? false {
            return
        }
        
        // check comment already exist in view
        for (group,c) in self.comments.enumerated() {
            if let index = c.index(where: { $0.uniqueId == message.uniqueId }) {
                self.comments[group][index] = message
                
                self.viewPresenter?.onUpdateComment(comment: message, indexpath: IndexPath(row: index, section: group))
            }
        }
        
    }
    
    func onMessageDeleted(message: QMessage){
        
        SharedPreferences.saveDeletedComment(uniqueId: message.uniqueId)
        var tempComment = [QMessage]()
        for (_,var c) in self.comments.enumerated() {
            if let index = c.index(where: { $0.uniqueId == message.uniqueId }) {
                c.remove(at: index)
                self.lastIdToLoad = ""
                self.loadMoreAvailable = true
            }
            
            tempComment.append(contentsOf: c)
        }
        
        self.comments = self.groupingComments(tempComment)
        self.viewPresenter?.onReloadComment()
    }
    
    func onUserTyping(userId : String, roomId : String, typing: Bool){
        if let user = self.qiscus.database.participant.find(byUserId : userId){
            self.viewPresenter?.onUser(name: user.name, typing: typing)
        }
    }
    
    //this func was deprecated
    func didDelete(Comment comment: QMessage) {
        //
    }
    
    //this func was deprecated
    func onRoom(update room: QChatRoom) {
        //
    }
    
    //this func was deprecated
    func didComment(comment: QMessage, changeStatus status: QMessageStatus) {
        //
    }
}

extension UIChatPresenter : QiscusConnectionDelegate {
    public func connectionState(change state: QiscusConnectionState) {
        print("::realtime connection state \(state)")
    }
    
    public func onConnected() {
        print("::realtime connected")
    }
    
    public func onReconnecting() {
        print("::realtime reconnecting")
    }
    
    public func onDisconnected(withError err: QError?) {
        guard let error = err else { return }
        print("::realtime disconnected \(error.message)")
    }
}
