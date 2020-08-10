//
//  WebFileViewController.swift
//  MultichannelWidget
//
//  Created by Rahardyan Bisma on 30/06/20.
//

import UIKit
import WebKit

class WebFileViewController: UIViewController {
    var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        return activityIndicator
    }()
    
    var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        return webView
    }()
    
    var fileUrl: String?
    var localFileUrl: URL?
    var fileName: String = "File Attachment"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.webView)
        self.view.addSubview(self.activityIndicator)
        self.webView.navigationDelegate = self
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        self.title = fileName
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                self.webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                self.webView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                self.activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                self.webView.topAnchor.constraint(equalTo: self.view.topAnchor),
                self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                self.activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            ])
        }
        
        guard let localFileUrl = self.localFileUrl else {
            guard let fileUrl = self.fileUrl, let url = URL(string: fileUrl) else {
                return
            }
            
            webView.load(URLRequest(url: url))
            return
        }
        
        
        webView.loadFileURL(localFileUrl, allowingReadAccessTo: localFileUrl)
        
    }

}

extension WebFileViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = true
    }
}
