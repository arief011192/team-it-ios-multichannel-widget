//
//  WebViewController.swift
//  Pods
//
//  Created by qiscus on 07/04/20.
//

#if os(iOS)
import UIKit
#endif
import WebKit

class WebViewController: UIViewController, WKUIDelegate {
    var webView: WKWebView!
    var url: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if url == nil {
            self.dismiss(animated: true, completion: nil)
        }
        let myRequest = URLRequest(url: URL(string: url!)!)
        webView.load(myRequest)
    }
    
    override func loadView() {
       let webConfiguration = WKWebViewConfiguration()
       webView = WKWebView(frame: .zero, configuration: webConfiguration)
       webView.uiDelegate = self
       view = webView
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
