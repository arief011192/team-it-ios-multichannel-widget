//
//  FullImageViewController.swift
//  MultichannelWidget
//
//  Created by qiscus on 17/03/20.
//

#if os(iOS)
import UIKit
#endif
import QiscusCore

class FullImageViewController: UIViewController {
    
    @IBOutlet weak var ivImage: UIImageView!
    
    var message: QMessage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if message != nil {
            if let url = message!.payload?["url"] as? String {
                if self.ivImage.image == nil {
                    self.ivImage.af.setImage(withURL: URL(string: url)!)
                }
            }
        }

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
