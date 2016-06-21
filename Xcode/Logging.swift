// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation

var globalLogLevel: LogLevel = .trace

public enum LogLevel: Int {
    case trace,
    debug,
    info,
    warning,
    error,
    off
}

extension String {
    
    func indentedLines(indent: String = "  ", separatedBy: String = "\n") -> String {
        return self.components(separatedBy: separatedBy)
            .map { return "\(indent)\($0)" }
            .joined(separator: separatedBy)
    }
}

extension Thread {
    
    class func indentedCallStackSymbols() -> String {
        return self.callStackSymbols().map { return "    " + $0 }.joined(separator: "\n")
    }
    
}

extension LogLevel : CustomStringConvertible {
    public var description: String {
        get {
            switch(self) {
            case .trace:
                return "TRACE"
            case .debug:
                return "DEBUG"
            case .info:
                return "INFO"
            case .warning:
                return "WARN"
            case .error:
                return "ERROR"
            case .off:
                return ""
            }
        }
    }
    
    public var paddedDescription: String {
        get {
            switch(self) {
            case .trace:
                return "  TRACE"
            case .debug:
                return "  DEBUG"
            case .info:
                return "   INFO"
            case .warning:
                return "⚠  WARN"
            case .error:
                return "☣ ERROR"
            case .off:
                return ""
            }
        }
    }
}


/**
 logs a message using the specified level
 
 :param: message the message to log, must return a string
 :param: level the log level of the message
 :param: function the calling function name
 :param: file the calling file
 :param: line the calling line
 
 :returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func log( _ message: @autoclosure() -> String, level: LogLevel = .debug, function: String = #function, file: String = #file, line: Int = #line, callstack: Bool = false) -> Void {
    
    if level.rawValue >= globalLogLevel.rawValue {
        let message = message()
        let f = URL(fileURLWithPath: file).lastPathComponent ?? "unknown"
        if callstack {
            print("[\(level.paddedDescription)] \(f):\(line) • \(function) - \(message)\nCallstack:\n\(Thread.indentedCallStackSymbols())")
        } else {
            print("[\(level.paddedDescription)] \(f):\(line) • \(function) - \(message)")
        }
    }
}

/**
 logs a error message
 
 :param: message the message to log, must return a string
 :param: function the calling function name
 :param: file the calling file
 :param: line the calling line
 
 :returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func error( _ message: @autoclosure() -> String, function: String = #function, file: String = #file, line: Int = #line, callstack: Bool = false) -> Void   {
    return log(message, level: .error, function: function, file: file, line: line, callstack: callstack)
}

/**
 logs a warning message
 
 :param: message the message to log, must return a string
 :param: function the calling function name
 :param: file the calling file
 :param: line the calling line
 
 :returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func warn( _ message: @autoclosure() -> String, function: String = #function, file: String = #file, line: Int = #line, callstack: Bool = false) -> Void   {
    return log(message, level: .warning, function: function, file: file, line: line, callstack: callstack)
}

/**
 logs a debug (trace) message
 
 :param: message the message to log, must return a string
 :param: function the calling function name
 :param: file the calling file
 :param: line the calling line
 
 :returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func debug( _ message: @autoclosure() -> String, function: String = #function, file: String = #file, line: Int = #line, callstack: Bool = false) -> Void  {
    return log(message, level: .debug, function: function, file: file, line: line, callstack: callstack)
}

/**
 logs an informative message
 
 :param: message the message to log, must return a string
 :param: function the calling function name
 :param: file the calling file
 :param: line the calling line
 
 :returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func info( _ message: @autoclosure() -> String, function: String = #function, file: String = #file, line: Int = #line, callstack: Bool = false) -> Void  {
    return log(message, level: .info, function: function, file: file, line: line, callstack: callstack)
}

/**
 logs a trace (finer than debug) message
 
 :param: message the message to log, must return a string
 :param: function the calling function name
 :param: file the calling file
 :param: line the calling line
 
 :returns: the log message used without any adornment such as function name, file, line
 */
@inline(__always)
public func trace( _ message: @autoclosure() -> String, function: String = #function, file: String = #file, line: Int = #line, callstack: Bool = false) -> Void  {
    return log(message, level: .trace, function: function, file: file, line: line, callstack: callstack)
}

/**
 logs a http request and reponse
 */
@inline(__always)
public func trace(_ description: String, request: URLRequest, data: NSData?, response: URLResponse?, error: NSError?, function: String = #function, file: String = #file, line: Int = #line) -> Void  {
    guard globalLogLevel.rawValue <= LogLevel.trace.rawValue else {
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
    
    trace(components.joined(separator: "\n"), function: function, file: file, line: line)
}
