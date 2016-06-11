// This source file is part of the ParticleSwift open source project
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See https://github.com/vakoc/particle-swift/blob/master/LICENSE for license information

import Foundation

public let errorDomain = "com.vakoc.ParticleSwift"

/// Enum for a result of something that can fail, particularly network requests
public enum Result<T> {
    case Success(T)
    case Failure(ErrorProtocol)
}


public protocol StringKeyedDictionaryConvertible {
    
    init? (dictionary: [String : AnyObject])
    
    var dictionaryRepresentation: [String : AnyObject] { get }
}

/**
 Protocol describing entities that provide the basic HTTP components needed to make a web service
 call.
 */
public protocol WebServiceCallable {
   
    /// The base URL to use to create the web service call */
    var baseURL: NSURL { get }
    
    /// The URL session to use to perform the web service request, typically with a data task */
    var urlSession: NSURLSession { get }
    
    /// the queue to use for invoking callbacks
    var dispatchQueue: dispatch_queue_t { get }
    
}

