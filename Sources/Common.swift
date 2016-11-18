// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation
import Dispatch

public let errorDomain = "com.vakoc.ParticleSwift"

/// Enum for a result of something that can fail, particularly network requests
public enum Result<T> {
    case success(T)
    case failure(Error)
}


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

