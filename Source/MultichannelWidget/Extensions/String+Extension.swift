//
//  String+Extension.swift
//  MultichannelWidget
//
//  Created by Rahardyan Bisma on 30/06/20.
//

import Foundation

extension String {
    var isPDF: Bool {
        guard let urlFileExtension = self.split(separator: ".").last, urlFileExtension.lowercased() == "pdf" else {
            return false
        }
        
        return true
    }
}
