//
//  QismoViewController.swift
//  Pods
//
//  Created by asharijuang on 08/01/20.
//

#if os(iOS)
import UIKit
#endif
import WebKit

class QismoViewController: UIViewController {

    var webView: WKWebView!
    var url: URL?
    @IBOutlet weak var containerView: UIView!
    
    init() {
        super.init(nibName: "QismoViewController", bundle: MultichannelWidget.bundle)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        // Disable zoom in web view
        let source: String = "var meta = document.createElement('meta');" +
        "meta.name = 'viewport';" +
        "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
        "var head = document.getElementsByTagName('head')[0];" + "head.appendChild(meta);"
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd,
        forMainFrameOnly: true)
        let contentController = WKUserContentController()
        contentController.addUserScript(script)
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.userContentController = contentController
        
        webView = WKWebView(frame: self.containerView.frame, configuration: webViewConfiguration)
        webView.navigationDelegate = self
        self.containerView.addSubview(webView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        webView.navigationDelegate = self
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.delegate = self
        guard let webUrl = self.url else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        webView.load(URLRequest(url: webUrl))
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: UIApplication.keyboardWillShowNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: UIApplication.keyboardWillHideNotification, object: nil)
        }

        @objc func keyboardWillShow(notification: NSNotification) {
            if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
                
            }
        }

        @objc func keyboardWillHide(notification: NSNotification) {

        }
}


extension QismoViewController: UIScrollViewDelegate {
    //MARK: - UIScrollViewDelegate
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

extension QismoViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let scrollableSize = CGSize(width: view.frame.size.width, height: webView.scrollView.contentSize.height)
        self.webView?.scrollView.contentSize = scrollableSize
//        self.webView.evaluateJavaScript("window.scrollTo(0,0)", completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            let path = url.absoluteString
            if path.contains("#logout") {
                decisionHandler(.cancel)
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.popViewController(animated: true)
                return
            }
        }
        decisionHandler(.allow)
    }
}
