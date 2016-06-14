// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information


import Foundation

/// The global logging level.  This can be changed at runtime
public var globalLogLevel: LogLevel = .Trace

/// Available logging levels
///
/// Logging messages use the following guidelines
///  - if the problem is unrecoverable, use error (uncommon)
///  - if the problem is an unexpected condtion that is handled it is a warning (common)
///  - info messages are human readable user level events that would typically be user initiated
///  - trace are all debug level messages that are targeted at ParticleSwift developers
///
/// Only trace level message may contain sensitive data (access tokens, for example).  Info level
/// messages may contain user identifying information but may not contain sensitive data (passwords 
/// or access tokens).  
///
/// ParticleSwift logging messages are never intended for use or display to customer/end users.  Error
/// handling at higher levels with localized messages should be used for that purpose.
public enum LogLevel: Int {
    case Trace,
    Info,
    Warning,
    Error
}

extension LogLevel : CustomStringConvertible {
    public var description: String {
        get {
            switch(self) {
            case .Trace:
                return "TRACE"
            case .Info:
                return "INFO"
            case .Warning:
                return "WARN"
            case .Error:
                return "ERROR"
            }
        }
    }
    
    public var paddedDescription: String {
        get {
            switch(self) {
            case .Trace:
                return "  TRACE"
            case .Info:
                return "   INFO"
            case .Warning:
                return "⚠  WARN"
            case .Error:
                return "☣ ERROR"
            }
        }
    }
}

/** 
 conditionally perform the closure iff the current loging level allows.  Used for more expensive blocks
 - parameter level the log level to check
 - parameter block the closure to conditionally run, returning the string to log
*/
@inline(__always)
public func logIf(level: LogLevel = .Trace, block: () -> String) {
    if level.rawValue >= globalLogLevel.rawValue {
        log(message: block(), level: level)
    }
}


/**
 logs a message using the specified level
 
 - parameter message: the message to log, must return a string
 - parameter level: the log level of the message
 - parameter function: the calling function name
 - parameter file: the calling file
 - parameter line: the calling line
 
 - returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func log( message: @autoclosure () -> String, level: LogLevel = .Trace, function: String = #function, file: String = #file, line: Int = #line) -> Void {
    
    if level.rawValue >= globalLogLevel.rawValue {
        let message = message()
        print("[\(level.paddedDescription)] \(file.lastPathComponent):\(line) • \(function) - \(message)")
    }
}

/**
 logs a error message
 
 - parameter message the message to log, must return a string
 - parameter function: the calling function name
 - parameter file: the calling file
 - parameter line: the calling line
 
 - returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
func error( message: @autoclosure () -> String, function: String = #function, file: String = #file, line: Int = #line) -> Void   {
    return log(message: message, level: .Error, function: function, file: file, line: line)
}

/**
 logs a warning message
 
 - parameter message the message to log, must return a string
 - parameter function: the calling function name
 - parameter file: the calling file
 - parameter line: the calling line
 
 - returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func warn( message: @autoclosure () -> String, function: String = #function, file: String = #file, line: Int = #line) -> Void   {
    return log(message: message, level: .Warning, function: function, file: file, line: line)
}

/**
 logs an informative message
 
 - parameter message the message to log, must return a string
 - parameter function: the calling function name
 - parameter file: the calling file
 - parameter line: the calling line
 
 - returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func info( message: @autoclosure () -> String, function: String = #function, file: String = #file, line: Int = #line) -> Void  {
    return log(message: message, level: .Info, function: function, file: file, line: line)
}

/**
 logs a trace (finer than debug) message
 
 - parameter message: the message to log, must return a string
 - parameter function: the calling function name
 - parameter file: the calling file
 - parameter line: the calling line
 
 - returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func trace( message: @autoclosure () -> String, function: String = #function, file: String = #file, line: Int = #line) -> Void  {
    return log(message: message, level: .Trace, function: function, file: file, line: line)
}

/**
 logs a http request and reponse
 */
@inline(__always)
public func trace(description: String, request: URLRequest, data: NSData?, response: URLResponse?, error: NSError?, function: String = #function, file: String = #file, line: Int = #line) -> Void  {
    guard globalLogLevel.rawValue <= LogLevel.Trace.rawValue else {
        return
    }
    
    var components = [description, "with \(request.httpMethod ?? "GET") request"]
    components.append("\(request)")
    if let headers = request.allHTTPHeaderFields {
        components.append("headers")
        components.append("\(headers)")
    }
    
    if let body = request.httpBody, bodyString = String(data: body, encoding: String.Encoding.utf8) {
        components.append("request body")
        components.append(bodyString)
    }
    
    if let response = response {
        components.append("returned")
        components.append("\(response)")
    }
    
    
    
    if let response = response as? HTTPURLResponse, contentType = response.allHeaderFields["Content-Type"] as? String  where contentType.contains("application/json"), let data = data, json = try? JSONSerialization.jsonObject(with: data as Data, options: []) {
        components.append("with response")
        components.append("\(json)")
        
    } else if let data = data, let body = String(data: data as Data, encoding: String.Encoding.utf8) {
        components.append("with response")
        components.append(body)
    }
    
    if let error = error {
        components.append("error:")
        components.append("\(error)")
    }
    
    trace(message: components.joined(separator: "\n"), function: function, file: file, line: line)
}

