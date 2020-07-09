//
//  File.swift
//  Pods
//
//  Created by qiscus on 21/01/20.
//

import Foundation

public class AppUtil {
    
    static func dateToHour(date: Date?) -> String {
        guard let date = date else {
            return "-"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone      = TimeZone.current
        let defaultTimeZoneStr = formatter.string(from: date);
        return defaultTimeZoneStr
    }

}
