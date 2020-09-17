//
//  Connectivity.swift
//  MultichannelWidget
//
//  Created by Rahardyan Bisma on 11/09/20.
//

import Foundation
import Alamofire

struct Connectivity {
  static let sharedInstance = NetworkReachabilityManager()!
  static var isInternetConnected:Bool {
      return self.sharedInstance.isReachable
    }
}
