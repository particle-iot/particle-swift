// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation
import VakocLogging

/// Represents the particle product
public enum Product: Int {
    /// Particle Core
    case Core = 0,
    /// Particle Photon
    Photon = 6,
    /// Particle Electron
    Electron = 10
    
    public func productString() -> String {
        switch (self) {
        case .Core:
            return "Core"
        case .Photon:
            return "Photon"
        case .Electron:
            return "Electron"
        }
    }
}


/// Represents a particle device (spark, photon, electron, etc)
public struct DeviceInformation {
    
    private struct DictionaryConstants {
        static let id = "id"
        static let name = "name"
        static let lastApp = "last_app"
        static let lastIPAddress = "last_ip_address"
        static let product = "product_id"
        static let lastHeard = "last_heard"
        static let connected = "connected"
        static let lastICCID = "last_iccid"
        static let imei = "imei"
        static let status = "status"
    }
    
    /// Device ID
    public let deviceID: String
    
    /// Indicates what product the device belongs to. Common values are 0 for Core, 6 for Photon.
    public let product: Product
    
    /// Device name
    public var name: String
    
    /// Name of the last application that was flashed to the device
    public var lastApp: String?
    
    /// IP Address that was most recently used by the device
    public var lastIPAddress: String?
    
    /// Date the cloud last heard from the device
    public var lastHeard: Date?
    
    /// Indicates whether the device is currently connected to the cloud
    public var connected: Bool = false
    
    /// Last SIM card ID number used if an Electron
    public var lastICCID: String?
    
    /// IMEI number if an Electron
    public var IMEI: String?
    
    /// TODO verify;  does the product support cellular connectivity
    public var cellular: Bool = false
    
    /// TODO verify (docs don't show); status (known to support "normal")
    public var status: String?
    
    /// Ceate a new device
    public init(deviceID: String, name: String, product: Product) {
        self.deviceID = deviceID
        self.name = name
        self.product = product
    }
    
    public mutating func update(deviceDetailInformation: DeviceDetailInformation) {
        self.name = deviceDetailInformation.name
        self.lastApp = deviceDetailInformation.lastApp
        self.connected = deviceDetailInformation.connected
        self.lastHeard = deviceDetailInformation.lastHeard
        self.lastICCID = deviceDetailInformation.lastICCID
        self.IMEI = deviceDetailInformation.imei
        self.status = deviceDetailInformation.status
        self.cellular = deviceDetailInformation.cellular
    }
}

extension DeviceInformation: StringKeyedDictionaryConvertible {
    public init?(with dictionary: [String : AnyObject]) {
        guard let deviceID = dictionary[DictionaryConstants.id] as? String where !deviceID.isEmpty,
            let name = dictionary[DictionaryConstants.name] as? String where !name.isEmpty,
            let productId = dictionary[DictionaryConstants.product] as? Int,
            let product = Product(rawValue: productId) else {
                warn("Failed to create a Device using the dictionary \(dictionary);  the required properties were not found")
                return nil;
        }
        self.init(deviceID: deviceID, name: name, product: product)
        
        self.lastApp = dictionary[DictionaryConstants.lastApp] as? String
        self.lastIPAddress = dictionary[DictionaryConstants.lastIPAddress] as? String
        self.lastHeard = (dictionary[DictionaryConstants.lastHeard] as? String)?.dateWithISO8601String
        self.connected = dictionary[DictionaryConstants.connected] as? Bool ?? false
        self.lastICCID = dictionary[DictionaryConstants.lastICCID] as? String
        self.IMEI = dictionary[DictionaryConstants.imei] as? String
        self.status = dictionary[DictionaryConstants.status] as? String
    }
    
    public var dictionary: [String : AnyObject] {
        get {
            var ret = [String : AnyObject]()
            ret[DictionaryConstants.id] = deviceID
            ret[DictionaryConstants.name] = name
            ret[DictionaryConstants.product] = product.rawValue
            ret[DictionaryConstants.lastApp] = lastApp
            ret[DictionaryConstants.lastIPAddress] = lastIPAddress
            ret[DictionaryConstants.lastHeard] = lastHeard?.ISO8601String
            ret[DictionaryConstants.connected] = connected
            ret[DictionaryConstants.lastICCID] = lastICCID
            ret[DictionaryConstants.imei] = IMEI
            ret[DictionaryConstants.status] = status
            return ret
        }
    }
}

extension DeviceInformation: Equatable { }
    
public func ==(lhs: DeviceInformation, rhs: DeviceInformation) -> Bool {
    
    return lhs.deviceID == rhs.deviceID &&
        lhs.product == rhs.product &&
        lhs.name == rhs.name &&
        lhs.lastApp == rhs.lastApp &&
        lhs.lastIPAddress == rhs.lastIPAddress &&
        lhs.lastHeard == rhs.lastHeard &&
        lhs.connected == rhs.connected &&
        lhs.lastICCID == rhs.lastICCID &&
        lhs.IMEI == rhs.IMEI &&
        lhs.cellular == rhs.cellular &&
        lhs.status == rhs.status    
}


/// The detail device information retrieved from /v1/devices/:deviceId
public struct DeviceDetailInformation {
    
    private struct DictionaryConstants {
        static let id = "id"
        static let name = "name"
        static let lastApp = "last_app"
        static let product = "product_id"
        static let lastHeard = "last_heard"
        static let connected = "connected"
        static let variables = "variables"
        static let functions = "functions"
        static let cc3000_patch_version = "cc3000_patch_version"
        static let requiresDeepUpdate = "requires_deep_update"
        static let lastICCID = "last_iccid"
        static let imei = "imei"
        static let status = "status"
    }
    
    /// Device ID
    public let deviceID: String

    /// Device name
    public var name: String
    
    /// Name of the last application that was flashed to the device
    public var lastApp: String?
    
    /// Indicates whether the device is currently connected to the cloud
    public var connected: Bool = false
    
    /// List of variable name and types exposed by the device in name: type format
    public var variables = [String : String]()
    
    /// List of function names exposed by the device
    public var functions = [String]()
    
    /// What version of the cc3000 firmware the devices is running. Only applies to Cores.
    public var cc3000_patch_version: String?
    
    /// Indicates what product the device belongs to. Common values are 0 for Core, 6 for Photon.
    public let product: Product
    
    /// Date the cloud last heard from the device
    public var lastHeard: Date?
    
    /// Whether this device requires the "Deep Update". Only applies to Cores.
    public var requiresDeepUpdate: Bool = false
    
    /// Last SIM card ID number used if an Electron
    public var lastICCID: String?
    
    /// IMEI number if an Electron
    public var imei: String?
    
    /// TODO verify (docs don't show); status (known to support "normal")
    public var status: String?
    
    /// TODO verify;  does the product support cellular connectivity
    public var cellular: Bool = false
    
    /// Ceate a new device
    public init(deviceID: String, name: String, product: Product) {
        self.deviceID = deviceID
        self.name = name
        self.product = product
    }
}

extension DeviceDetailInformation: StringKeyedDictionaryConvertible {
    
    public init?(with dictionary: [String : AnyObject]) {
        guard let deviceID = dictionary[DictionaryConstants.id] as? String where !deviceID.isEmpty,
            let name = dictionary[DictionaryConstants.name] as? String where !name.isEmpty,
            let productId = dictionary[DictionaryConstants.product] as? Int,
            let product = Product(rawValue: productId) else {
                warn("Failed to create a Device using the dictionary \(dictionary);  the required properties were not found")
                return nil;
        }
        
        self.init(deviceID: deviceID, name: name, product: product)
        
        self.lastApp = dictionary[DictionaryConstants.lastApp] as? String
        //self.lastIPAddress = dictionary["last_ip_address"] as? String
        self.lastHeard = (dictionary[DictionaryConstants.lastHeard] as? String)?.dateWithISO8601String
        self.connected = dictionary[DictionaryConstants.connected] as? Bool ?? false
        
        if let variables = dictionary[DictionaryConstants.variables] as? [String : String] {
            self.variables = variables
        }
        
        if let functions = dictionary[DictionaryConstants.functions] as? [String] {
            self.functions = functions
        }
        
        self.cc3000_patch_version = dictionary[DictionaryConstants.cc3000_patch_version] as? String
        self.requiresDeepUpdate = dictionary[DictionaryConstants.requiresDeepUpdate] as? Bool ?? false
        self.lastICCID = dictionary[DictionaryConstants.lastICCID] as? String
        self.imei = dictionary[DictionaryConstants.imei] as? String
        self.status = dictionary[DictionaryConstants.status] as? String
    }
    
    public var dictionary: [String : AnyObject] {
        get {
            var ret = [String : AnyObject]()
            ret[DictionaryConstants.id] = deviceID
            ret[DictionaryConstants.name] = name
            ret[DictionaryConstants.product] = product.rawValue
            ret[DictionaryConstants.lastApp] = lastApp
            ret[DictionaryConstants.lastHeard] = lastHeard?.ISO8601String
            ret[DictionaryConstants.connected] = connected
            ret[DictionaryConstants.variables] = variables
            ret[DictionaryConstants.functions] = functions
            ret[DictionaryConstants.cc3000_patch_version] = cc3000_patch_version
            ret[DictionaryConstants.requiresDeepUpdate] = requiresDeepUpdate
            ret[DictionaryConstants.lastICCID] = lastICCID
            ret[DictionaryConstants.imei] = imei
            ret[DictionaryConstants.status] = status
            return ret
        }
    }

}
// MARK: Devices
extension ParticleCloud {
    
    /// Asynchronously obtain the devices associated with the Particle Cloud account
    ///
    /// This method will invoke authenticate with validateToken = false.  Any authentication error will be returned
    /// if not successful
    ///
    /// - parameter completion: completion handler. Contains the DeviceInformation array or failure result
    public func devices(completion: (Result<[DeviceInformation]>) -> Void ) {
        
        self.authenticate(validateToken: false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let accessToken):
                
                var request = URLRequest(url: try! self.baseURL.appendingPathComponent("v1/devices"))
                
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Creating particle devices", request: request, data: data, response: response, error: error)
                    
                    
                    if let error = error {
                        return completion(.failure(ParticleError.deviceListFailed(error)))
                    }
                    
                    if let data = data, json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String : AnyObject]],  j = json {
                        
                        
                        return completion(.success(j.flatMap({ return DeviceInformation(with: $0)})))
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        
                        warn("failed to obtain devices with response: \(response) and message body \(message)")
                        
                        /// todo: this error is wrong
                        let error = NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed to obtain active devices: \(message)", tableName: nil, bundle: Bundle(for: self.dynamicType), comment: "The http request obtain the devices failed with message: \(message)")])
                        
                        return completion(.failure(ParticleError.deviceListFailed(error)))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func deviceDetailInformation(device: DeviceInformation, completion: (Result<DeviceDetailInformation>) -> Void ) {
        
        authenticate(validateToken: false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                
                var request = URLRequest(url: try! self.baseURL.appendingPathComponent("v1/devices/\(device.deviceID)"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Get device detail information", request: request, data: data, response: response, error: error)
                    if let error = error {
                        return completion(.failure(ParticleError.listAccessTokensFailed(error)))
                    }
                    
                    if let data = data, json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject],  j = json, deviceDetailInformation = DeviceDetailInformation(with: j) {
                        return completion(.success(deviceDetailInformation))
                    } else {
                        let error = NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed to obtain detail device information", tableName: nil, bundle: Bundle(for: self.dynamicType), comment: "The http request to create an OAuthToken failed")])
                        
                        return completion(.failure(ParticleError.listAccessTokensFailed(error)))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func deviceDetailInformation(deviceID: String, completion: (Result<DeviceDetailInformation>) -> Void ) {
        
        authenticate(validateToken: false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                
                var request = URLRequest(url: try! self.baseURL.appendingPathComponent("v1/devices/\(deviceID)"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Get device detail information", request: request, data: data, response: response, error: error)
                    if let error = error {
                        return completion(.failure(ParticleError.listAccessTokensFailed(error)))
                    }
                    
                    if let data = data, json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject],  j = json, deviceDetailInformation = DeviceDetailInformation(with: j) {
                        return completion(.success(deviceDetailInformation))
                    } else {
                        let error = NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed to obtain detail device information", tableName: nil, bundle: Bundle(for: self.dynamicType), comment: "The http request to create an OAuthToken failed")])
                        
                        return completion(.failure(ParticleError.listAccessTokensFailed(error)))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func callFunction(functionName: String, deviceID: String, argument: String?, completion: (Result<[String : AnyObject]>) -> Void ) {
        
        authenticate(validateToken: false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                
                var request = URLRequest(url: try! self.baseURL.appendingPathComponent("v1/devices/\(deviceID)/\(functionName)"))
                request.httpMethod = "POST"
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                if let argument = argument {
                    request.httpBody = ["arg" : argument].jsonString?.data(using: String.Encoding.utf8)
                }
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Call function", request: request, data: data, response: response, error: error)
                    
                    
                    if let error = error {
                        return completion(.failure(ParticleError.listAccessTokensFailed(error)))
                    }
                    
                    if let data = data, json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject],  j = json {
                        return completion(.success(j))
                    } else {
                        let error = NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed to invoke function \(functionName)", tableName: nil, bundle: Bundle(for: self.dynamicType), comment: "The request failed")])
                        
                        return completion(.failure(ParticleError.listAccessTokensFailed(error)))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func variableValue(variableName: String, deviceID: String, completion: (Result<[String : AnyObject]>) -> Void ) {
        
        authenticate(validateToken: false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                
                var request = URLRequest(url: try! self.baseURL.appendingPathComponent("v1/devices/\(deviceID)/\(variableName)"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Get variable value", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.listAccessTokensFailed(error)))
                    }
                    
                    if let data = data, json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject],  j = json {
                        return completion(.success(j))
                    } else {
                        let error = NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed to obtain variable \(variableName)", tableName: nil, bundle: Bundle(for: self.dynamicType), comment: "The request failed")])                        
                        return completion(.failure(ParticleError.listAccessTokensFailed(error)))
                    }
                }
                task.resume()
            }
        }
    }
    
}



