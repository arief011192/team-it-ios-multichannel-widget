//
//  QChatVC.swift
//  Qiscus
//
//  Created by Rahardyan Bisma on 07/05/18.
//

import UIKit
import ContactsUI
import SwiftyJSON
import QiscusCoreApi

// Chat view blue print or function
protocol UIChatView {
    func uiChat(viewController : UIChatViewController, didSelectMessage message: CommentModel)
    func uiChat(viewController : UIChatViewController, performAction action: Selector, forRowAt message: CommentModel, withSender sender: Any?)
    func uiChat(viewController : UIChatViewController, canPerformAction action: Selector, forRowAtmessage: CommentModel, withSender sender: Any?) -> Bool
    func uiChat(viewController : UIChatViewController, firstMessage message: CommentModel, viewForHeaderInSection section: Int) -> UIView?
}

class DateHeaderLabel: UILabel {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = #colorLiteral(red: 0.3555911001, green: 0.7599821354, blue: 1, alpha: 0.7924068921)
        textColor = .darkGray
        textAlignment = .center
        translatesAutoresizingMaskIntoConstraints = false // enables auto layout
        font = UIFont.boldSystemFont(ofSize: 9.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        let originalContentSize = super.intrinsicContentSize
        let height = originalContentSize.height + 12
        layer.cornerRadius = height / 2
        layer.masksToBounds = true
        return CGSize(width: originalContentSize.width + 15, height: height)
    }
    
}

class UIChatViewController: UIViewController {
    
    public init() {
        super.init(nibName: "UIChatViewController", bundle: MultichannelWidget.bundle)
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
     
    @IBOutlet weak var tableViewConversation: UITableView!
    @IBOutlet weak var viewChatInput: UIView!
    @IBOutlet weak var constraintViewInputBottom: NSLayoutConstraint!
    @IBOutlet weak var constraintViewInputHeight: NSLayoutConstraint!
    @IBOutlet weak var emptyMessageView: UIView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var heightProgressBar: NSLayoutConstraint!
    
    lazy var chatTitleView : UIChatNavigation = {
        return UIChatNavigation()
    }()
    
    var chatInput : CustomChatInput = CustomChatInput()
    var disableInput: DisableInput = DisableInput()
    private var presenter: UIChatPresenter = UIChatPresenter()
    
    var heightAtIndexPath: [String: CGFloat] = [:]
    var roomId: String {
        set(newValue) {
            self.presenter.loadRoom(withId: newValue)
        }
        get {
            return self.presenter.room?.id ?? ""
        }
    }
    var chatDelegate : UIChatView? = nil
    var isFromUploader = false
    var isResolved = false
    
    // UI Config
    var usersColor : [String:UIColor] = [String:UIColor]()
    var currentNavbarTint = UINavigationBar.appearance().tintColor
    var latestNavbarTint = UINavigationBar.appearance().tintColor
    var maxUploadSizeInKB:Double = Double(100) * Double(1024)
    var UTIs:[String]{
        get{
            return ["public.jpeg", "public.png","com.compuserve.gif","public.text", "public.archive", "com.microsoft.word.doc", "com.microsoft.excel.xls", "com.microsoft.powerpoint.​ppt", "com.adobe.pdf","public.mpeg-4"]
        }
    }
    var room : RoomModel? {
        set(newValue) {
            self.presenter.room = newValue
            self.refreshUI()
        }
        get {
            return self.presenter.room
        }
    }
    
    var synchTimer: Timer?
    
    open func getProgressBar() -> UIProgressView {
        return progressBar
    }
    
    open func getProgressBarHeight() ->  NSLayoutConstraint{
        return heightProgressBar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.presenter.attachView(view: self)
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(UIChatViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(UIChatViewController.keyboardChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        center.addObserver(self,selector: #selector(reSubscribeRoom(_:)), name: Notification.Name(rawValue: "reSubscribeRoom"),object: nil)
        view.endEditing(true)
        
        //sync timer
        synchTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { timer in
            self.presenter.syncMessage() 
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //disable timer
        synchTimer?.invalidate()
        
        self.presenter.detachView()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "reSubscribeRoom"), object: nil)
        view.endEditing(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.presenter.detachView()
    }
    
    @objc func reSubscribeRoom(_ notification: Notification)
    {
        self.presenter.attachView(view: self)
    }

    
    func setupToolbarHandle(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapFunction))
        self.chatTitleView.isUserInteractionEnabled = true
        self.chatTitleView.addGestureRecognizer(tap)
    }
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        if self.room != nil {
            if self.room?.type == .group{
//                let vc = RoomInfoVC()
//                vc.room = room
//                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                // no action for type single
            }
        }
    }
    
    func refreshUI() {
        if self.isViewLoaded {
            self.presenter.attachView(view: self)
            self.setupUI()
        }
    }
    
    // MARK: View Event Listener
    private func setupUI() {
        // config navBar
        self.setupNavigationTitle()
        self.setupToolbarHandle()
        self.qiscusAutoHideKeyboard()
        self.setupTableView()
        self.chatInput.chatInputDelegate = self
        self.chatInput.replyChatInputDelegate = self
        self.disableInput.disableInputDelegate = self
        if self.isResolved {
            self.setupDisableInput(self.disableInput)
        } else {
            self.setupInputBar(self.chatInput)
        }
        
    }
    
    private func setupInputBar(_ inputchatview: UIChatInput) {
        inputchatview.frame.size    = self.viewChatInput.frame.size
        inputchatview.frame.origin  = CGPoint.init(x: 0, y: 0)
        inputchatview.translatesAutoresizingMaskIntoConstraints = false
        inputchatview.delegate = self
        
        self.viewChatInput.addSubview(inputchatview)
        
        NSLayoutConstraint.activate([
            inputchatview.topAnchor.constraint(equalTo: self.viewChatInput.topAnchor, constant: 0),
            inputchatview.leftAnchor.constraint(equalTo: self.viewChatInput.leftAnchor, constant: 0),
            inputchatview.rightAnchor.constraint(equalTo: self.viewChatInput.rightAnchor, constant: 0),
            inputchatview.bottomAnchor.constraint(equalTo: self.viewChatInput.bottomAnchor, constant: 0)
            ])
        
    }
    
    private func setupDisableInput(_ disableInput: DisableInput) {
        disableInput.frame.size    = self.viewChatInput.frame.size
        disableInput.frame.origin  = CGPoint.init(x: 0, y: 0)
        disableInput.translatesAutoresizingMaskIntoConstraints = false
//        disableInput.delegate = self
        
        self.viewChatInput.addSubview(disableInput)
        
        NSLayoutConstraint.activate([
            disableInput.topAnchor.constraint(equalTo: self.viewChatInput.topAnchor, constant: 0),
            disableInput.leftAnchor.constraint(equalTo: self.viewChatInput.leftAnchor, constant: 0),
            disableInput.rightAnchor.constraint(equalTo: self.viewChatInput.rightAnchor, constant: 0),
            disableInput.bottomAnchor.constraint(equalTo: self.viewChatInput.bottomAnchor, constant: 0)
            ])
    }
    
    private func setupNavigationTitle(){
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = false
        }
        var totalButton = 1
        if let leftButtons = self.navigationItem.leftBarButtonItems {
            totalButton += leftButtons.count
        }
        if let rightButtons = self.navigationItem.rightBarButtonItems {
            totalButton += rightButtons.count
        }
        
        let backButton = self.backButton(self, action: #selector(UIChatViewController.goBack))
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItems = [backButton]
        
        self.chatTitleView = UIChatNavigation(frame: self.navigationController?.navigationBar.frame ?? CGRect.zero)
        self.navigationItem.titleView = chatTitleView
        self.chatTitleView.room = self.room
        
        let callButton = UIBarButtonItem(image: UIImage(named: "phone", in: MultichannelWidget.bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(call))
        self.navigationItem.rightBarButtonItem = callButton
    }
    
    private func backButton(_ target: UIViewController, action: Selector) -> UIBarButtonItem{
        let backIcon = UIImageView()
        backIcon.contentMode = .scaleAspectFit
        
        let image = UIImage(named: "ic_arrow_back", in: MultichannelWidget.bundle, compatibleWith: nil)?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        backIcon.image = image
        backIcon.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        backIcon.contentMode = .scaleAspectFit
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            backIcon.frame = CGRect(x: 0,y: 11,width: 20,height: 20)
        }else{
            backIcon.frame = CGRect(x: 22,y: 11,width: 20,height: 20)
        }
        
        let backButton = UIButton(frame:CGRect(x: 0,y: 0,width: 30,height: 44))
        backButton.addSubview(backIcon)
        backButton.addTarget(target, action: action, for: UIControl.Event.touchUpInside)
        return UIBarButtonItem(customView: backButton)
    }
    
    private func setupTableView() {
        let rotate = CGAffineTransform(rotationAngle: .pi)
        self.tableViewConversation.transform = rotate
        self.tableViewConversation.scrollIndicatorInsets = UIEdgeInsets(top: 0,left: 0,bottom: 0,right: UIScreen.main.bounds.width - 8)
        self.tableViewConversation.rowHeight = UITableView.automaticDimension
        self.tableViewConversation.dataSource = self
        self.tableViewConversation.delegate = self
        self.tableViewConversation.scrollsToTop = false
        self.tableViewConversation.allowsSelection = false
        self.chatDelegate = self
        
        // support variation comment type
        self.registerClass(nib: UINib(nibName: "QTextRightCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qTextRightCell")
        self.registerClass(nib: UINib(nibName: "QTextLeftCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qTextLeftCell")
        self.registerClass(nib: UINib(nibName: "QImagesRightCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qImagesRightCell")
        self.registerClass(nib: UINib(nibName: "QFileRightCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qFileRightCell")
         self.registerClass(nib: UINib(nibName: "QFileLeftCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qFileLeftCell")
        self.registerClass(nib: UINib(nibName: "QImagesLeftCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qImagesLeftCell")
        self.registerClass(nib: UINib(nibName: "QLocationLeftViewCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qLocationLeftCell")
        self.registerClass(nib: UINib(nibName: "QLocationRightCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qLocationRightCell")
        self.registerClass(nib: UINib(nibName: "QFileLeftCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qFileLeftCell")
        self.registerClass(nib: UINib(nibName: "QFileRightCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qFileRightCell")
        self.registerClass(nib: UINib(nibName: "QReplyLeftCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qReplyLeftCell")
        self.registerClass(nib: UINib(nibName: "QReplyRightCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qReplyRightCell")
        self.registerClass(nib: UINib(nibName: "EmptyCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "emptyCell")
        self.registerClass(nib: UINib(nibName: "QCardLeftCell", bundle: MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qCardLeftCell")
        self.registerClass(nib: UINib(nibName: "QSystemCell", bundle:MultichannelWidget.bundle), forMessageCellWithReuseIdentifier: "qSystemCell")
        
        
    }
    
    @objc func goBack() {
        view.endEditing(true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func call() {
        
    }
    
    // MARK: - Keyboard Methode
    @objc func keyboardWillHide(_ notification: Notification){
        let info: NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        
        let animateDuration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        self.constraintViewInputBottom.constant = 0
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func keyboardChange(_ notification: Notification){
        let info:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardHeight: CGFloat = keyboardSize.height
        let animateDuration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        
        self.constraintViewInputBottom.constant = 0 - keyboardHeight
        UIView.animate(withDuration: animateDuration, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func getParticipant() -> String {
        var result = ""
        for m in self.presenter.participants {
            if result.isEmpty {
                result = m.username
            }else {
                result = result + ", \(m.username)"
            }
        }
        return result
    }
    
    // MARK : method
    func registerClass(nib: UINib?, forMessageCellWithReuseIdentifier reuseIdentifier: String) {
        self.tableViewConversation.register(nib, forCellReuseIdentifier: reuseIdentifier)
    }
    
    
    func setBackground(with image: UIImage) {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.transform = imageView.transform.rotated(by: CGFloat(Double.pi))
        self.tableViewConversation.isOpaque = false
        self.tableViewConversation.backgroundView =   imageView
    }
    
    func setBackground(with color: UIColor) {
        self.tableViewConversation.backgroundColor = color
    }
    
    func scrollToComment(comment: CommentModel) {
        if let indexPath = self.presenter.getIndexPath(comment: comment) {
            self.tableViewConversation.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    func cellFor(message: CommentModel, at indexPath: IndexPath, in tableView: UITableView) -> UIBaseChatCell {
        let menuConfig = enableMenuConfig()
        var colorName:UIColor = UIColor.lightGray
        
        if message.type == "text" {
            if (message.isMyComment() == true){
                let cell = tableView.dequeueReusableCell(withIdentifier: "qTextRightCell", for: indexPath) as! QTextRightCell
                cell.menuConfig = menuConfig
                cell.cellMenu = self
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "qTextLeftCell", for: indexPath) as! QTextLeftCell
                if self.room?.type == .group {
                    cell.colorName = colorName
                    cell.isPublic = true
                }else {
                    cell.isPublic = false
                }
                cell.openUrl = { url in
                    let webView = WebViewController()
                    webView.url = url.absoluteString
                    self.navigationController?.pushViewController(webView, animated: true)
                }
                cell.cellMenu = self
                return cell
            }
        } else if message.type == "system_event" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "qSystemCell", for: indexPath) as! QSystemCell
            return cell
        } else if  message.type == "file_attachment" {
            guard let payload = message.payload else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath) as! EmptyCell
                    return cell
            }
                
            if let url = payload["url"] as? String {
                let ext = message.fileExtension(fromURL:url)
                if(ext.contains("jpg") || ext.contains("png") || ext.contains("heic") || ext.contains("jpeg") || ext.contains("tif") || ext.contains("gif")){
                    if (message.isMyComment() == true){
                        let cell = tableView.dequeueReusableCell(withIdentifier: "qImagesRightCell", for: indexPath) as! QImagesRightCell
//                        cell.menuConfig = menuConfig
                        cell.actionBlock = { comment in
                         
                          let fullImage = FullImageViewController(nibName: "FullImageViewController", bundle: MultichannelWidget.bundle)
                          fullImage.message = comment
                          self.navigationController?.pushViewController(fullImage, animated: true)
                        }

                        cell.cellMenu = self
                        return cell
                    }else{
                        let cell = tableView.dequeueReusableCell(withIdentifier: "qImagesLeftCell", for: indexPath) as! QImagesLeftCell
//                        if self.room?.type == .group {
//                            cell.colorName = colorName
//                            cell.isPublic = true
//                        }else {
//                            cell.isPublic = false
//                        }
                        cell.actionBlock = { comment in
                           
                            let fullImage = FullImageViewController(nibName: "FullImageViewController", bundle: MultichannelWidget.bundle)
                            fullImage.message = comment
                            self.navigationController?.pushViewController(fullImage, animated: true)
                          }

                        cell.cellMenu = self
                        return cell
                    }
                } else {
                    if (message.isMyComment() == true){
                        let cell = tableView.dequeueReusableCell(withIdentifier: "qFileRightCell", for: indexPath) as! QFileRightCell
//                        cell.menuConfig = menuConfig
                            cell.cellMenu = self
                                return cell
                            } else {
                                let cell = tableView.dequeueReusableCell(withIdentifier: "qFileLeftCell", for: indexPath) as! QFileLeftCell
//                        if self.room?.type == .group {
//                            cell.colorName = colorName
//                            cell.isPublic = true
//                        }else {
//                            cell.isPublic = false
//                        }
                            cell.cellMenu = self
                            return cell
                        }
                }
            } else {
                if (message.isMyComment() == true){
                    let cell = tableView.dequeueReusableCell(withIdentifier: "qTextRightCell", for: indexPath) as! QTextRightCell
                    cell.menuConfig = menuConfig
                    cell.cellMenu = self
                    return cell
                }else{
                    let cell = tableView.dequeueReusableCell(withIdentifier: "qTextLeftCell", for: indexPath) as! QTextLeftCell
                    if self.room?.type == .group {
                        cell.colorName = colorName
                        cell.isPublic = true
                    }else {
                        cell.isPublic = false
                    }
                    cell.cellMenu = self
                    return cell
                }
            }
        } else if message.type == "reply" {
            if message.isMyComment() == true {
                let cell = tableView.dequeueReusableCell(withIdentifier: "qReplyRightCell", for: indexPath) as! QReplyRightCell
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "qReplyLeftCell", for: indexPath) as! QReplyLeftCell
                if self.room?.type == .group {
                    cell.colorName = colorName
                    cell.isPublic = true
                }else {
                    cell.isPublic = false
                }
                cell.cellMenu = self
                return cell
            }
        } else if message.type == "card" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "qCardLeftCell", for: indexPath) as! QCardLeftCell
            cell.menuConfig = menuConfig
            cell.actionBlock = { customButton in
                let webView = WebViewController()
                webView.url = customButton.url
                self.navigationController?.pushViewController(webView, animated: true)
            }
            cell.cellMenu = self
            
            return cell
            
        }
            let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath) as! EmptyCell
            return cell
    }
}

// MARK: UIChatDelegate
extension UIChatViewController: UIChatViewDelegate {
    func onReloadComment(){
        self.tableViewConversation.reloadData()
    }
    func onUpdateComment(comment: CommentModel, indexpath: IndexPath) {
        // reload cell in section and index path
        if self.tableViewConversation.cellForRow(at: indexpath) != nil{
            self.tableViewConversation.reloadRows(at: [indexpath], with: .none)
        }
    }
    
    func onLoadMessageFailed(message: String) {
        //
    }
    
    func onUser(name: String, isOnline: Bool, message: String) {
        self.chatTitleView.labelSubtitle.text = message
    }
    
    func onUser(name: String, typing: Bool) {
        if typing {
            if let room = self.presenter.room {
                if room.type == .group {
                    self.chatTitleView.labelSubtitle.text = "\(name) is Typing..."
                }else {
                    self.chatTitleView.labelSubtitle.text = "is Typing..."
                }
            }
        }else {
            if let room = self.presenter.room {
                if room.type == .group {
                    self.chatTitleView.labelSubtitle.text = getParticipant()
                }else{
                    self.chatTitleView.labelSubtitle.text = "Online"
                }
            }
        }
    }
    
    func onSendingComment(comment: CommentModel, newSection: Bool) {
        self.emptyMessageView.alpha = 0
        if newSection {
            self.tableViewConversation.beginUpdates()
            self.tableViewConversation.insertSections(IndexSet(integer: 0), with: .left)
            self.tableViewConversation.endUpdates()
        } else {
            let indexPath = IndexPath(row: 0, section: 0) // all view rotate because of this
            self.tableViewConversation.beginUpdates()
            self.tableViewConversation.insertRows(at: [indexPath], with: .left)
            self.tableViewConversation.endUpdates()
        }
    }
    
    func onLoadRoomFinished(roomName: String, roomAvatarURL: URL?) {
        if let _room = room {
            self.chatTitleView.room = _room
        }
        
        if self.presenter.comments.count == 0 {
            self.tableViewConversation.isHidden = true
            self.emptyMessageView.alpha = 1
        }else{
            self.tableViewConversation.isHidden = false
            self.emptyMessageView.alpha = 0
        }
        
        //this because after upload image can't update tableview. then need reload comments from chat-sdk
        if isFromUploader {
            self.presenter.loadRoom(withId: roomId)
        
            self.isFromUploader = false
        }
    }
    
    func onLoadRoomFinished(room: RoomModel) {
        self.setupUI()
    }
    
    func onLoadMoreMesageFinished() {
        self.tableViewConversation.reloadData()
    }
    
    func onLoadMessageFinished() {
        if self.presenter.comments.count == 0 {
            self.tableViewConversation.isHidden = true
            self.emptyMessageView.alpha = 1
        }else{
            self.tableViewConversation.isHidden = false
            self.emptyMessageView.alpha = 0
        }
        
        self.tableViewConversation.reloadData()
    }
    
    func onSendMessageFinished(comment: CommentModel) {
        
    }
    
    func onGotNewComment(newSection: Bool) {
        if self.presenter.comments.count == 0 {
            self.tableViewConversation.isHidden = true
            self.emptyMessageView.alpha = 1
        }else{
            if(self.tableViewConversation.isHidden == true){
                self.tableViewConversation.isHidden = false
                self.emptyMessageView.alpha = 0
            }
        }
        
        if Thread.isMainThread {
            if newSection {
                self.tableViewConversation.beginUpdates()
                self.tableViewConversation.insertSections(IndexSet(integer: 0), with: .right)
                self.tableViewConversation.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
                self.tableViewConversation.endUpdates()
            } else {
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableViewConversation.beginUpdates()
                self.tableViewConversation.insertRows(at: [indexPath], with: .right)
                self.tableViewConversation.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
                self.tableViewConversation.endUpdates()
            }
        }
    }
    
    func onRoomResolved(isResolved: Bool) {
        if isResolved {
            self.isResolved = isResolved
            self.setupDisableInput(self.disableInput)
        }
    }
    
    func onClosingMessageReceived(url: String) {
        let webView = WebViewController()
        webView.url = url
        self.navigationController?.pushViewController(webView, animated: true)
    }
}

extension UIChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionCount = self.presenter.comments.count
        let rowCount = self.presenter.comments[section].count
        if sectionCount == 0 {
            return 0
        }
        return rowCount
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.presenter.comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK: table cell confi
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // get mesage at indexpath
        let comment = self.presenter.getMessage(atIndexPath: indexPath)
        var cell = self.cellFor(message: comment, at: indexPath, in: tableView)
        cell.comment = comment
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        // Load More
        let comments = self.presenter.comments
        if indexPath.section == comments.count - 1 && indexPath.row > comments[indexPath.section].count - 10 {
            presenter.loadMore()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let firstMessageInSection = self.presenter.comments[section].first {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, d MMM"
            let dateString = dateFormatter.string(from: firstMessageInSection.date)
            
            let label = DateHeaderLabel()
            label.text = dateString
            
            let containerView = UIView()
            containerView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            containerView.addSubview(label)
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
            
            return containerView
            
        }
        return nil
    }
    
}

extension UIChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // get mesage at indexpath
        let comment = self.presenter.getMessage(atIndexPath: indexPath)
        self.chatDelegate?.uiChat(viewController: self, didSelectMessage: comment)
    }


    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        let comment = self.presenter.getMessage(atIndexPath: indexPath)
        if let response = self.chatDelegate?.uiChat(viewController: self, canPerformAction: action, forRowAtmessage: comment, withSender: sender) {
            return response
        }else {
            return false
        }
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        let comment = self.presenter.getMessage(atIndexPath: indexPath)
        self.chatDelegate?.uiChat(viewController: self, performAction: action, forRowAt: comment, withSender: sender)
    }

}

extension UIChatViewController : UIChatView {
    func uiChat(viewController: UIChatViewController, didSelectMessage message: CommentModel) {
        
    }
    
    func uiChat(viewController: UIChatViewController, performAction action: Selector, forRowAt message: CommentModel, withSender sender: Any?) {
        if action == #selector(UIResponderStandardEditActions.copy(_:)) {
            let pasteboard = UIPasteboard.general
            pasteboard.string = message.message
        }
    }
    
    func uiChat(viewController: UIChatViewController, canPerformAction action: Selector, forRowAtmessage: CommentModel, withSender sender: Any?) -> Bool {
        switch action.description {
        case "copy:":
            return true
        case "deleteComment:":
            return true
        case "replyComment:":
            return true
        default:
            return false
        }
    }
    
    func uiChat(viewController: UIChatViewController, firstMessage message: CommentModel, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
}

extension UIChatViewController : UIChatInputDelegate {
    func onHeightChanged(height: CGFloat) {
        self.constraintViewInputHeight.constant = height
    }
    
    func typing(_ value: Bool) {
        self.presenter.isTyping(value)
    }
    
    func send(message: CommentModel,onSuccess: @escaping (CommentModel) -> Void, onError: @escaping (String) -> Void) {
        
        if message.roomId.isEmpty || message.roomId == "" {
            if let room = self.room {
                message.roomId = room.id
            }
        }
        
        self.presenter.sendMessage(withComment: message, onSuccess: { (comment) in
            if (self.tableViewConversation.isHidden == true) {
                self.tableViewConversation.isHidden = false
                self.emptyMessageView.alpha = 0
            }
            self.presenter.isTyping(false)
            onSuccess(comment)
        }) { (error) in
            self.presenter.isTyping(false)
            onError(error)
        }
    }
    
    func setFromUploader(comment: CommentModel) {
        self.isFromUploader = true
    }
}

extension UIChatViewController : ReplyChatInputDelegate {
    func hideReply() {
        self.constraintViewInputHeight.constant = 50
    }
    
}

extension UIChatViewController : DisableChatInputDelegate {
    func startNewChat(vc: UIChatViewController) {
        var vcArray = self.navigationController?.viewControllers
        vcArray!.removeLast()
        vcArray!.append(vc)
        self.navigationController?.setViewControllers(vcArray!, animated: true)
    }
    
    func finishVC() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

//// MARK: Handle Cell Menu
extension UIChatViewController : UIBaseChatCellDelegate {
    func didTap(delete comment: CommentModel) {
        
        let alert = UIAlertController(title: "Alert", message: "Want to delete this message ?", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { action in
            self.presenter.deleteMessage(comment: comment)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func didReply(reply comment: CommentModel) {
        self.chatInput.showReplyView(comment: comment)
        self.constraintViewInputHeight.constant = 100
    }

}
