// This source file is part of the ParticleSwift open source project
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See https://github.com/vakoc/particle-swift/blob/master/LICENSE for license information


import Foundation

extension NSDate {
    
    /// Returns self as an ISO8601 formatted string
    var ISO8601String: String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.string(from: self)
    }
}

extension String {
    
    var dateWithISO8601String: NSDate? {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.date(from: self)
    }
    
    /// The last path component of a string
    ///
    /// basically anything after the last forward
    /// slash or self if it does not contain a forward slash
    var lastPathComponent: String {
        
        guard let lastRange = self.range(of: "/", options: [.backwardsSearch]) else {
            return self
        }
        return self.substring(with: lastRange.upperBound..<self.endIndex)
    }
}

extension Dictionary where Key: StringLiteralConvertible, Value: StringLiteralConvertible {
    
    var URLEncodedParameters: String? {
        
        let comps = NSURLComponents(string: "http://www.vakoc.com/")
        
        comps?.queryItems = self.map( { (key, value) -> NSURLQueryItem  in return NSURLQueryItem(name: "\(key)", value: "\(value)") })
        return comps?.percentEncodedQuery
    }
}

extension Dictionary where Key: StringLiteralConvertible, Value: Any {
    
    var jsonString: String?  {
        if let dict = (self as? AnyObject) as? Dictionary<String, AnyObject> {
            do {
                let data = try NSJSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted])
                if let string = String(data: data, encoding: NSUTF8StringEncoding) {
                    return string
                }
            } catch {
                warn(message: "Failed to convert \(self) to JSON with error \(error)")
            }
        }
        return nil
    }
}

extension Array where Element: AnyObject {
    
    var jsonString: String?  {

        do {
            let data = try NSJSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
            if let string = String(data: data, encoding: NSUTF8StringEncoding) {
                return string
            }
        } catch {
            warn(message: "Failed to convert \(self) to JSON with error \(error)")
        }
        return nil
    }
}

