// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation

/// A Particle Cloud Webhook
public struct Webhook {
    
    /// Webhook HTTP methods
    ///
    /// - GET: HTTP Get
    /// - POST: HTTP Post
    /// - PUT: HTTP Put
    /// - DELETE: HTTP Delete
    public enum RequestType: String {
        case get = "GET", post = "POST", put = "PUT", delete = "DELETE"
    }
    
    /// Unique identifier for the webhook
    var id: String
    
    /// The date the webhook was created
    var created: Date?
    
    // The name of the Particle event that will trigger the webhook
    var event: String
    
    /// The web address that will be targeted when the webhook is triggered
    var url: URL
    
    /// Type of web request triggered by the webhook that can be set
    var requestType: RequestType = .get
    
    /// Limits the webhook triggering to devices owned by you
    var mydevices: Bool = true
    
    /// Limits the webhook triggering to a single device
    var deviceID: String?
    
    /// Custom data sent as JSON with the request
    var json: [String : Any]?
    
    /// Custom data sent a form with the request
    var form: [String : Any]?
    
    /// Query parameters added to the URL of the request
    var query: [String : Any]?
    
    /// Custom HTTP headers included with the request
    var headers: [String : String]?
    
    /// A customized webhook response event name that your devices can subscribe to
    var responseTopic: String?
    
    /// A customized webhook error response event name that your devices can subscribe to
    var errorResponseTopic: String?
    
    /// If true, will not add the triggering Particle event's data to the webhook request
    var noDefaults: Bool = false
    
    /// If false, skip SSL certificate validation of the target URL
    var rejectUnauthorized: Bool = true
    
    /// Create a Webhook using the supplied dictionary.  
    ///
    /// Returns nil if the dictionary does not contain all the required information
    ///
    /// - parameter dictionary:  The dictionary containing the webhook information
    public init?(with dictionary: Dictionary<String,Any>) {
        
        guard let id = dictionary["id"] as? String, let event = dictionary["event"] as? String, let urlString = dictionary["url"] as? String, let url = URL(string: urlString) else {
            warn("Failed to create Webhook due to missing required values in \(dictionary)")
            return nil
        }
        
        self.id = id
        self.event = event
        self.url = url
        
        if let created_at = dictionary["created_at"] as? String, let created = created_at.dateWithISO8601String {
            self.created = created
        }
        
        if let deviceID = dictionary["deviceID"] as? String, !deviceID.isEmpty {
            self.deviceID = deviceID
        }
        
        if let requestType = dictionary["requestType"] as? String, let rt = RequestType(rawValue: requestType.uppercased()) {
            self.requestType = rt
        }
        
        if let mydevices = dictionary.bool(for: "mydevices") {
            self.mydevices = mydevices
        }
        
        if let noDefaults = dictionary.bool(for: "noDefaults") {
            self.noDefaults = noDefaults
        }
        
        if let rejectUnauthorized = dictionary.bool(for: "rejectUnauthorized") {
            self.rejectUnauthorized = rejectUnauthorized
        }
        self.form = dictionary["form"] as? Dictionary<String,Any>
        self.query = dictionary["query"] as? Dictionary<String,Any>
        self.json = dictionary["json"] as? Dictionary<String,Any>
        self.headers = dictionary["headers"] as? Dictionary<String,String>
        
        self.responseTopic = dictionary["responseTopic"] as? String
        self.responseTopic = dictionary["errorResponseTopic"] as? String
    }
    
    /// JSON Representation of the webhook
    public var jsonRepresentation: [String : Any] {

        var ret = [String : Any]()
        ret["id"] = id
        ret["event"] = event
        ret["url"] = url.absoluteString
        ret["requestType"] = requestType.rawValue
        ret["mydevices"] = mydevices
        ret["noDefaults"] = noDefaults
        ret["rejectUnauthorized"] = rejectUnauthorized
        
        
        if let created = created { ret["created_at"] = created.ISO8601String }
        if let deviceID = deviceID { ret["deviceID"] = deviceID }
        if let form = form { ret["form"] = form }
        if let json = json { ret["json"] = json }
        if let query = query { ret["query"] = query }
        if let headers = headers  { ret["headers "] = headers  }
        if let responseTopic = responseTopic { ret["errorResponseTopic"] = responseTopic }

        return ret
    }
}

extension Webhook: Equatable {
    
    static public func == (lhs: Webhook, rhs: Webhook) -> Bool {
        return lhs.id == rhs.id &&
            lhs.event == rhs.event &&
            lhs.url == rhs.url &&
            lhs.requestType == rhs.requestType &&
            lhs.mydevices == rhs.mydevices &&
            lhs.deviceID == rhs.deviceID &&
//            lhs.json == rhs.json &&
//            lhs.form == rhs.form &&
//            lhs.query == rhs.query &&
//            lhs.headers == rhs.query &&
            lhs.responseTopic == rhs.responseTopic &&
            lhs.errorResponseTopic == rhs.errorResponseTopic &&
            lhs.noDefaults == rhs.noDefaults &&
            lhs.rejectUnauthorized == rhs.rejectUnauthorized
    }
}


// MARK: Webhooks
extension ParticleCloud {
    
    /// Asynchronously obtain the webhooks available by product or account
    ///
    /// This method will invoke authenticate with validateToken = false.  Any authentication error will be returned
    /// if not successful
    ///
    /// - parameter completion: completion handler. Contains an array of Webhook objects
    public func webhooks(productIdOrSlug: String? = nil, completion: @escaping (Result<[Webhook]>) -> Void ) {
        
        self.authenticate(false) { (result) in
            switch (result) {
                
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                var request = URLRequest(url: productIdOrSlug != nil ? self.baseURL.appendingPathComponent("v1/products/\(productIdOrSlug)/webhooks") : self.baseURL.appendingPathComponent("v1/webhooks"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
               
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Listing all webhooks", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.webhookListFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String : AnyObject]],  let j = json {
                        return completion(.success(j.flatMap({ return Webhook(with: $0)})))
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        warn("failed to list all webhooks with response: \(response) and message body \(message)")
                        
                        /// todo: this error is wrong
                        let error = NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed to obtain active webhooks: \(message)", tableName: nil, bundle: Bundle(for: type(of: self)), comment: "The http request obtain the webhooks failed with message: \(message)")])
                        
                        return completion(.failure(ParticleError.webhookListFailed(error)))
                    }
                }
                task.resume()
            }
        }
    }
    
}



