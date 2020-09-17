//
//  QismoNetworkManagerV2.swift
//  MultichannelWidget
//
//  Created by Rahardyan Bisma on 16/07/20.
//

import Foundation
import QiscusCore
import Alamofire
import SwiftyJSON

class QismoNetworkManager {
    
    var qiscus: QiscusCore
    var qiscusUser: QAccount?
    let urlInitiateChat = "https://multichannel.qiscus.com/api/v1/qiscus/initiate_chat"
    
    public init(qiscusCore : QiscusCore) {
        self.qiscus = qiscusCore
    }
    
    public func initiateChat(param: [String:Any], onSuccess: @escaping(String) -> Void, onError: @escaping(String) -> Void) {
        var mParam = param
        self.qiscus.getJWTNonce(onSuccess: { nonce in
//            mParam = ["nonce" : nonce.nonce]
            mParam.updateValue(nonce.nonce, forKey: "nonce")
            //self.callInitiateChat(param: mParam, onSuccess: onSuccess, onError: onError)
            let request = AF.request(self.urlInitiateChat, method: .post, parameters: mParam, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                print("network result \(response.result)")
                guard let value = response.value as? [String: Any],
                let chat = value["data"] as? [String: Any] else {
                  return
                }
                //get identityToken
                guard let identityToken = chat["identity_token"] as? String else {
                    onError("Failed to parsing token")
                    return
                }
                
                guard let roomId = chat["room_id"] as? String else {
                    onError("failed to parsing room id")
                    return
                }
                //login sdk
                self.setQismoSdkUser(identityToken: identityToken, onSuccess: { [weak self] user in
                    //success login sdk
                    self?.qiscusUser = user
                    SharedPreferences.saveQiscusAccount(userEmail: user.id)
                    self?.qiscus.connect()
                    onSuccess(roomId)
                }, onError: { qError in
                    debugPrint(qError.message)
                })
                
            }.cURLDescription { curl in
                print("initiate chat \(curl)")
            }
            
        }, onError: { error in
            print(error.message)
            onError(error.message)
        })
    }
    
    private func callInitiateChat(param: [String:Any], onSuccess: @escaping() -> Void, onError: @escaping() -> Void) {
        let url = "https://multichannel.qiscus.com/api/v1/qiscus/initiate_chat"
        AF.request(URL(string: url)!, method: .post, parameters: param)
            .responseJSON { json in
                
            }
    }
    
    public func setQismoSdkUser(identityToken: String, onSuccess: @escaping(QAccount) -> Void, onError: @escaping(QError) -> Void) {
        self.qiscus.setUserWithIdentityToken(token: identityToken, onSuccess: { user in
            onSuccess(user)
        }, onError: { qError in
            onError(qError)
        })
    }
    
    public func getQismoRoom(roomId: String, onSuccess: @escaping(QChatRoom) -> Void, onError: @escaping(QError) -> Void) {
        self.qiscus.shared.getChatRooms(roomIds: [roomId], onSuccess: { (room) in
            
        }) { (error) in
            
        }
        
    }
    
}

