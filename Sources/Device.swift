// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation

/// Represents a particle device (spark, photon, electron, etc)
public struct DeviceInformation {
    
    /// Represents the particle product
    public enum Product: Int, CustomStringConvertible {
        /// Particle Core
        case core = 0,
        /// Particle Photon
        photon = 6,
        /// Particle Electron
        electron = 10
        
        
        public var description: String {
            switch (self) {
            case .core:
                return "Core"
            case .photon:
                return "Photon"
            case .electron:
                return "Electron"
            }
        }
    }
    
    fileprivate enum DictionaryConstants: String {
        case id
        case name
        case lastApp = "last_app"
        case lastIPAddress = "last_ip_address"
        case product = "product_id"
        case lastHeard = "last_heard"
        case connected
        case lastICCID = "last_iccid"
        case imei
        case status
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
    
    /// Update the device with the content of the new device detail
    ///
    /// - Parameter deviceDetailInformation: updated device detail information
    public mutating func update(_ deviceDetailInformation: DeviceDetailInformation) {
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
    
    public init?(with dictionary: [String : Any]) {
        guard let deviceID = dictionary[DictionaryConstants.id.rawValue] as? String , !deviceID.isEmpty,
            let name = dictionary[DictionaryConstants.name.rawValue] as? String , !name.isEmpty,
            let productIdString = dictionary[DictionaryConstants.product.rawValue] as? CustomStringConvertible,
            let productId = Int("\(productIdString)"),
            let product = Product(rawValue: productId) else {
                warn("Failed to create a Device using the dictionary \(dictionary);  the required properties were not found")
                return nil;
        }
        self.init(deviceID: deviceID, name: name, product: product)
        
        self.lastApp = dictionary[DictionaryConstants.lastApp.rawValue] as? String
        self.lastIPAddress = dictionary[DictionaryConstants.lastIPAddress.rawValue] as? String
        self.lastHeard = (dictionary[DictionaryConstants.lastHeard.rawValue] as? String)?.dateWithISO8601String
        self.connected = dictionary[DictionaryConstants.connected.rawValue] as? Bool ?? false
        self.lastICCID = dictionary[DictionaryConstants.lastICCID.rawValue] as? String
        self.IMEI = dictionary[DictionaryConstants.imei.rawValue] as? String
        self.status = dictionary[DictionaryConstants.status.rawValue] as? String
    }
    
    /// The device information as a dictionary using keys compatible with the original web service
    public var dictionary: [String : Any] {
        get {
            var ret = [String : Any]()
            ret[DictionaryConstants.id.rawValue] = deviceID
            ret[DictionaryConstants.name.rawValue] = name
            ret[DictionaryConstants.product.rawValue] = product.rawValue
            ret[DictionaryConstants.lastApp.rawValue] = lastApp
            ret[DictionaryConstants.lastIPAddress.rawValue] = lastIPAddress
            ret[DictionaryConstants.lastHeard.rawValue] = lastHeard?.ISO8601String
            ret[DictionaryConstants.connected.rawValue] = connected
            ret[DictionaryConstants.lastICCID.rawValue] = lastICCID
            ret[DictionaryConstants.imei.rawValue] = IMEI
            ret[DictionaryConstants.status.rawValue] = status
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
    
    fileprivate enum DictionaryConstants: String {
        case id
        case name
        case lastApp = "last_app"
        case product = "product_id"
        case lastHeard = "last_heard"
        case connected
        case variables
        case functions
        case cc3000_patch_version = "cc3000_patch_version"
        case requiresDeepUpdate = "requires_deep_update"
        case lastICCID = "last_iccid"
        case imei
        case status
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
    public let product: DeviceInformation.Product
    
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
    public init(deviceID: String, name: String, product: DeviceInformation.Product) {
        self.deviceID = deviceID
        self.name = name
        self.product = product
    }
}

extension DeviceDetailInformation: StringKeyedDictionaryConvertible {
    
    public init?(with dictionary: [String : Any]) {
        guard let deviceID = dictionary[DictionaryConstants.id.rawValue] as? String , !deviceID.isEmpty,
            let name = dictionary[DictionaryConstants.name.rawValue] as? String , !name.isEmpty,
            let productIdString = dictionary[DictionaryConstants.product.rawValue] as? CustomStringConvertible,
            let productId = Int("\(productIdString)"),
            let product = DeviceInformation.Product(rawValue: productId) else {
                warn("Failed to create a Device using the dictionary \(dictionary);  the required properties were not found")
                return nil;
        }
        
        self.init(deviceID: deviceID, name: name, product: product)
        
        self.lastApp = dictionary[DictionaryConstants.lastApp.rawValue] as? String
        //self.lastIPAddress = dictionary["last_ip_address"] as? String
        self.lastHeard = (dictionary[DictionaryConstants.lastHeard.rawValue] as? String)?.dateWithISO8601String
        self.connected = dictionary[DictionaryConstants.connected.rawValue] as? Bool ?? false
        
        if let variables = dictionary[DictionaryConstants.variables.rawValue] as? [String : String] {
            self.variables = variables
        }
        
        if let functions = dictionary[DictionaryConstants.functions.rawValue] as? [String] {
            self.functions = functions
        }
        
        self.cc3000_patch_version = dictionary[DictionaryConstants.cc3000_patch_version.rawValue] as? String
        self.requiresDeepUpdate = dictionary[DictionaryConstants.requiresDeepUpdate.rawValue] as? Bool ?? false
        self.lastICCID = dictionary[DictionaryConstants.lastICCID.rawValue] as? String
        self.imei = dictionary[DictionaryConstants.imei.rawValue] as? String
        self.status = dictionary[DictionaryConstants.status.rawValue] as? String
    }
    
    /// The device detail information as a dictionary using keys compatible with the original web service
    public var dictionary: [String : Any] {
        get {
            var ret = [String : Any]()
            ret[DictionaryConstants.id.rawValue] = deviceID
            ret[DictionaryConstants.name.rawValue] = name
            ret[DictionaryConstants.product.rawValue] = product.rawValue
            ret[DictionaryConstants.lastApp.rawValue] = lastApp
            ret[DictionaryConstants.lastHeard.rawValue] = lastHeard?.ISO8601String
            ret[DictionaryConstants.connected.rawValue] = connected
            ret[DictionaryConstants.variables.rawValue] = variables
            ret[DictionaryConstants.functions.rawValue] = functions
            ret[DictionaryConstants.cc3000_patch_version.rawValue] = cc3000_patch_version
            ret[DictionaryConstants.requiresDeepUpdate.rawValue] = requiresDeepUpdate
            ret[DictionaryConstants.lastICCID.rawValue] = lastICCID
            ret[DictionaryConstants.imei.rawValue] = imei
            ret[DictionaryConstants.status.rawValue] = status
            return ret
        }
    }
}

public struct ClaimResult {
    
    enum DictionaryConstants: String {
        case claimCode = "claim_code"
        case deviceIDs = "device_ids"
    }
    
    public var claimCode: String
    
    public var deviceIDs: [String]
}

extension ClaimResult: Equatable {}

public func ==(lhs: ClaimResult, rhs: ClaimResult) -> Bool {
    return lhs.claimCode == rhs.claimCode && lhs.deviceIDs == rhs.deviceIDs
}

extension ClaimResult: StringKeyedDictionaryConvertible {
    
    public init? (with dictionary: [String : Any]) {
        guard let claimCode = dictionary[DictionaryConstants.claimCode.rawValue] as? String,
            let deviceIDs = dictionary[DictionaryConstants.deviceIDs.rawValue] as? [String] else {
                return nil
        }
        self.claimCode = claimCode
        self.deviceIDs = deviceIDs
    }
    
    /// The claim result as a dictionary using keys compatible with the original web service
    public var dictionary: [String : Any] {
        return [DictionaryConstants.claimCode.rawValue : claimCode, DictionaryConstants.deviceIDs.rawValue: deviceIDs]
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
    public func devices(_ completion: @escaping (Result<[DeviceInformation]>) -> Void ) {
        
        self.authenticate(false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let accessToken):
                
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/devices"))
                
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Creating particle devices", request: request, data: data, response: response, error: error)
                    
                    
                    if let error = error {
                        return completion(.failure(ParticleError.deviceListFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String : Any]],  let j = json {
                        
                        
                        return completion(.success(j.flatMap({ return DeviceInformation(with: $0)})))
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        
                        warn("failed to obtain devices with response: \(String(describing: response)) and message body \(String(describing: message))")
                        
                        return completion(.failure(ParticleError.deviceListFailed(ParticleError.httpReponseParseFailed(message))))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func deviceDetailInformation(_ device: DeviceInformation, completion: @escaping (Result<DeviceDetailInformation>) -> Void ) {
        
        authenticate(false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/devices/\(device.deviceID)"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Get device detail information", request: request, data: data, response: response, error: error)
                    if let error = error {
                        return completion(.failure(ParticleError.deviceDetailedInformationFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],  let j = json, let deviceDetailInformation = DeviceDetailInformation(with: j) {
                        return completion(.success(deviceDetailInformation))
                    } else {
                        return completion(.failure(ParticleError.deviceDetailedInformationFailed(ParticleError.httpReponseParseFailed(nil))))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func deviceDetailInformation(_ deviceID: String, completion: @escaping (Result<DeviceDetailInformation>) -> Void ) {
        
        authenticate( false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/devices/\(deviceID)"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Get device detail information", request: request, data: data, response: response, error: error)
                    if let error = error {
                        return completion(.failure(ParticleError.deviceDetailedInformationFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],  let j = json, let deviceDetailInformation = DeviceDetailInformation(with: j) {
                        return completion(.success(deviceDetailInformation))
                    } else {
                        return completion(.failure(ParticleError.deviceDetailedInformationFailed(ParticleError.httpReponseParseFailed(nil))))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func callFunction(_ functionName: String, deviceID: String, argument: String?, completion: @escaping (Result<[String : Any]>) -> Void ) {
        
        authenticate(false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/devices/\(deviceID)/\(functionName)"))
                request.httpMethod = "POST"
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                if let argument = argument {
                    request.httpBody = ["arg" : argument].jsonString?.data(using: String.Encoding.utf8)
                }
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Call function", request: request, data: data, response: response, error: error)
                    
                    
                    if let error = error {
                        return completion(.failure(ParticleError.callFunctionFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],  let j = json {
                        return completion(.success(j))
                    } else {
                        return completion(.failure(ParticleError.callFunctionFailed(ParticleError.httpReponseParseFailed(nil))))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func variableValue(_ variableName: String, deviceID: String, completion: @escaping (Result<[String : Any]>) -> Void ) {
        
        authenticate( false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let accessToken):
                
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/devices/\(deviceID)/\(variableName)"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Get variable value", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.variableValueFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],  let j = json {
                        return completion(.success(j))
                    } else {
                        return completion(.failure(ParticleError.variableValueFailed(ParticleError.httpReponseParseFailed(nil))))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func claim(_ deviceID: String, completion: @escaping (Result<Int>) -> Void ) {
        trace("attempting to claim device \(deviceID)")
        authenticate(false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let accessToken):
                
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/devices"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = ["id" : deviceID].URLEncodedParameters?.data(using: String.Encoding.utf8)

                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Claim device", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.claimDeviceFailed(error)))
                    }
                    // TODO: what does this actually return?
                    completion(.success((response as! HTTPURLResponse).statusCode))
                }
                task.resume()
            }
        }
    }
    
    public func unclaim(_ deviceID: String, completion: @escaping (Result<[String: Any]>) -> Void ) {
        trace("attempting to unclaim device \(deviceID)")
        authenticate(false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let accessToken):
                
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/devices/\(deviceID)"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.httpMethod = "DELETE"
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Unclaim device", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.unclaimDeviceFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],  let j = json {
                        return completion(.success(j))
                    } else {
                        return completion(.failure(ParticleError.unclaimDeviceFailed(ParticleError.httpReponseParseFailed(nil))))
                    }
                }
                task.resume()
            }
        }
    }
    
    public func transfer(_ deviceID: String, completion: @escaping (Result<String>) -> Void ) {
        trace("attempting to transfer device \(deviceID)")
        authenticate(false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let accessToken):
                
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/devices"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = ["id" : deviceID, "request_transfer" : "true"].URLEncodedParameters?.data(using: String.Encoding.utf8)
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Transfer device", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.transferDeviceFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],  let j = json, let transferid = j["transfer_id"] as? String {
                        return completion(.success(transferid))
                    } else {
                        return completion(.failure(ParticleError.transferDeviceFailed(ParticleError.httpReponseParseFailed(nil))))
                    }
                }
                task.resume()
            }
        }
    }

    public func createClaimCode(_ imei: String? = nil, iccid: String? = nil, completion: @escaping (Result<ClaimResult>) -> Void ) {
        trace("attempting to create a claim code")

        authenticate(false) { (result) in
            switch (result) {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let accessToken):
                
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/device_claims"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.httpMethod = "POST"
                
                var args = [String : String]()
                if let imei = imei {
                    args["imei"] = imei
                }
                if let iccid = iccid {
                    args["iccid"] = iccid
                }
                if !args.isEmpty {
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    request.httpBody = args.URLEncodedParameters?.data(using: String.Encoding.utf8)
                }
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace("Create claim code", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.createClaimCode(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],  let j = json, let claimCode = ClaimResult(with: j) {
                        return completion(.success(claimCode))
                    } else {
                        return completion(.failure(ParticleError.createClaimCode(ParticleError.httpReponseParseFailed(nil))))
                    }
                }
                task.resume()
            }
        }
    }
}



