// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation
import Dispatch

/// Enum for a result of something that can fail, particularly on asynchronous actions like network requests
///
/// - success: The action succedded;  the associated value is the operation result
/// - failure: The action failed;  the associated value is an error
public enum Result<T> {
    case success(T)
    case failure(Error)
}


/// Items that can be initialized from and converted to a dictionary with string keys
public protocol StringKeyedDictionaryConvertible {
    
    init? (with dictionary: [String : Any])
    
    var dictionary: [String : Any] { get }
}

/**
 Protocol describing entities that provide the basic HTTP components needed to make a web service
 call.
 */
public protocol WebServiceCallable {
   
    /// The base URL to use to create the web service call */
    var baseURL: URL { get }
    
    /// The URL session to use to perform the web service request, typically with a data task */
    var urlSession: URLSession { get }
    
    /// the queue to use for invoking callbacks
    var dispatchQueue: DispatchQueue { get }
    
}

