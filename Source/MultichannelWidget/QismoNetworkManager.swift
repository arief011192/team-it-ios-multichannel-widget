//
//  QismoNetworkManager.swift
//  Pods
//
//  Created by qiscus on 04/02/20.
//

import Foundation
import QiscusCoreAPI
import Alamofire
import SwiftyJSON

class QismoNetworkManager {
    
    var qiscus: QiscusCoreAPI
    let urlInitiateChat = "https://multichannel.qiscus.com/api/v1/qiscus/initiate_chat"
    
    public init(QiscusCoreAPI : QiscusCoreAPI) {
        self.qiscus = QiscusCoreAPI
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
                self.setQismoSdkUser(identityToken: identityToken, onSuccess: { user in
                    //success login sdk
                    onSuccess(roomId)
                }, onError: { qError in
                    debugPrint(qError.message)
                })
                
            }
            print("initiate chat \(request.description)")
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
    
    public func setQismoSdkUser(identityToken: String, onSuccess: @escaping(UserModel) -> Void, onError: @escaping(QError) -> Void) {
        self.qiscus.setUserWithIdentityToken(token: identityToken, onSuccess: { user in
            onSuccess(user)
        }, onError: { qError in
            onError(qError)
        })
    }
    
    public func getQismoRoom(roomId: String, onSuccess: @escaping(RoomModel) -> Void, onError: @escaping(QError) -> Void) {
        
        self.qiscus.getChatRoom(id: roomId, onSuccess: { room, comments in
            
        }, onError: { qError in
            
        })
        
    }
    
}
