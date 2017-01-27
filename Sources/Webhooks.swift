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
    
    /// The counters returned by the get webhook command
    var counters: [Counter]?
    
    /// The log entries returned by the get webhook command
    var logs: [Log]?
    
    /// Webhook Counter
    public struct Counter {
        
        /// The date of the counter
        public var date: Date
        
        /// The success result?
        public var success: String
        
        /// Whether an error occurred
        public var error: Bool
        
        /// Create a Counter, or nil if the dictionary doesn't contain the required bits
        init?(_ dictionary: Dictionary<String,Any>) {
            
            guard let date = dictionary["date"] as? String, let parsedDate = date.dateWithYearMonthDay, let success = dictionary["success"] as? String else {
                return nil
            }
            self.date = parsedDate
            self.success = success
            self.error = dictionary.bool(for: "error") ?? false
        }
        
        /// JSON representation of the counter
        public var jsonRepresentation: [String : Any] {
            var ret = [String : Any]()
            ret["date"] = date.yearMonthDayString
            ret["success"] = success
            if error == true {
                ret["error"] = true
            }
            return ret
        }
    }
    
    /// A Webhook log entry
    public struct Log {
        
        /// The event that triggered the Webhook
        public struct Event {
            
            /// The event data
            public var data: String
            
            /// Name of the event
            public var event: String
            
            /// The device identifier that triggered the event
            public var coreid: String
            
            /// The date the event was published
            public var published: Date
            
            /// Create the event, or nil if the dictionary doesn't contain all the required information
            init?(_ dictionary: Dictionary<String,Any>) {
                guard let coreid = dictionary["coreid"] as? String, let data = dictionary["data"] as? String, let event = dictionary["event"] as? String, let published_at = dictionary["published_at"] as? String,
                    let published = published_at.dateWithISO8601String else {
                        return nil
                }
                self.data = data
                self.event = event
                self.coreid = coreid
                self.published = published
            }
            
            /// JSON representation of the event
            public var jsonRepresentation: [String : Any] {
                var ret = [String : Any]()
                ret["data"] = data
                ret["event"] = event
                ret["coreid"] = coreid
                ret["published_at"] = published.ISO8601String
                return ret
            }
        }
        
        /// The triggering event
        public var event: Event
        
        /// The webhook request
        public var request: String
        
        /// The webhook response
        public var response: String

        /// The time of the logged evenet
        public var time: Date
        
        /// The log type
        public var type: String
        
        /// Create a Counter, or nil if the dictionary doesn't contain the required bits
        init?(_ dictionary: Dictionary<String,Any>) {
            
            guard let eventString = dictionary["event"] as? [String : Any], let event = Event(eventString),
                let response = dictionary["response"] as? String, let request = dictionary["request"] as? String,
                let timeNumberString = dictionary["time"] as? CustomStringConvertible,
                let timeNumber = Int("\(timeNumberString)"),
                let type = dictionary["type"] as? String else {
                    return nil
            }
            
            self.event = event
            self.request = request
            self.response = response
            self.time = Date(timeIntervalSince1970: TimeInterval(timeNumber))
            self.type = type
            
        }
        
        /// JSON representation of the counter
        public var jsonRepresentation: [String : Any] {
            var ret = [String : Any]()
            
            ret["event"] = event.jsonRepresentation
            ret["request"] = request
            ret["response"] = response
            ret["time"] = Int(time.timeIntervalSince1970)
            ret["type"] = type
            return ret
        }
    }
    
    /// Creates a webhook 
    ///
    /// Webhooks created by this method are intended or use in the ParticleCloud.createWebhook 
    /// method.  Properties are either manually configured or read from a dictionary using the 
    /// configure(with:) method.  The id of all Webhook instances created with this constructor
    /// will be an empty string
    public init(event: String, url: URL, requestType: RequestType = .get) {
        self.id = ""
        self.event = event
        self.url = url
        self.requestType = requestType
    }
    
    /// Create a Webhook using the supplied dictionary.  
    ///
    /// Returns nil if the dictionary does not contain all the required information
    ///
    /// - parameter dictionary:  The dictionary containing the webhook information
    public init?(with dictionary: Dictionary<String,Any>) {
        
        guard let event = dictionary["event"] as? String, let urlString = dictionary["url"] as? String, let url = URL(string: urlString) else {
            warn("Failed to create Webhook due to missing required values in \(dictionary)")
            return nil
        }
        
        self.id = dictionary["id"] as? String ?? ""
        self.event = event
        self.url = url
        
        configure(with: dictionary)
    }
    
    /// Initialize the properties of the Webhook from the specified dictionary
    ///
    /// Non-optional properties id, event, and url are not modified by this method.  Use
    /// an appropriate constructor instead
    public mutating func configure(with dictionary: Dictionary<String, Any>) {
    
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
        
        // the following are returned only from the GetWebhook command
        if let counters = dictionary["counters"] as? [Dictionary<String,Any>] {
            self.counters = counters.flatMap { Counter($0) }
        }
        
        // the following are returned only from the GetWebhook command
        if let logs = dictionary["logs"] as? [Dictionary<String,Any>] {
            self.logs = logs.flatMap { Log($0) }
        }
        
    }
    
    /// JSON Representation of the webhook
    public var jsonRepresentation: [String : Any] {

        var ret = [String : Any]()

        if !id.isEmpty {
            ret["id"] = id
        }
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

        if let counters = counters {
            ret["counters"] = counters.map { $0.jsonRepresentation }
        }
        
        if let logs = logs {
            ret["logs"] = logs.map { $0.jsonRepresentation }
        }

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
    
    
    /// Asynchronously create a new webhook in the ParticleCloud
    ///
    /// - parameter webhook: the Webhook to create
    /// - parameter productIdOrSlug: Product ID or slug (only for product webhooks)
    /// - parameter completion:  callback invoked with the asynchronous result
    public func create(webhook: Webhook, productIdOrSlug: String? = nil, completion: @escaping (Result<Webhook>) -> Void ) {
        
        self.authenticate(false) { result in
            switch result {
                
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                var request = URLRequest(url: productIdOrSlug != nil ? self.baseURL.appendingPathComponent("v1/products/\(String(describing: productIdOrSlug))/webhooks") : self.baseURL.appendingPathComponent("v1/webhooks"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.httpMethod = "POST"
                
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = webhook.jsonRepresentation.jsonString?.data(using: .utf8)
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Created webhook", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.createWebhookFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let j = json, let id = j["id"] as? String, j.bool(for: "ok") == true {
                        
                        var newWebhook = webhook
                        newWebhook.configure(with: j)
                        newWebhook.id = id
                        return completion(.success(newWebhook))
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        warn("failed to create webhook with response: \(String(describing: response)) and message body \(message)")
                        
                        return completion(.failure(ParticleError.createWebhookFailed(ParticleError.httpReponseParseFailed(message))))
                    }
                }
                task.resume()
            }
        }
    }
    
    /// Asynchronously delete a new webhook in the ParticleCloud
    ///
    /// - parameter webhookID: the id Webhook to delete
    /// - parameter productIdOrSlug: Product ID or slug (only for product webhooks)
    /// - parameter completion:  callback invoked with the asynchronous result
    public func delete(webhookID: String, productIdOrSlug: String? = nil, completion: @escaping (Result<Bool>) -> Void ) {
        
        self.authenticate(false) { result in
            switch result {
                
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                var request = URLRequest(url: productIdOrSlug != nil ? self.baseURL.appendingPathComponent("v1/products/\(String(describing: productIdOrSlug))/webhooks/\(webhookID)") : self.baseURL.appendingPathComponent("v1/webhooks/\(webhookID)"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.httpMethod = "DELETE"
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Delete webhook", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.createWebhookFailed(error)))
                    }
                    
                    if let response = response as? HTTPURLResponse, response.statusCode == 204 {
                        return completion(.success(true))
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        warn("failed to delete webhook \(webhookID) with response: \(String(describing:response)) and message body \(message)")
                        
                        return completion(.failure(ParticleError.deleteWebhookFailed(webhookID, ParticleError.httpReponseParseFailed(message))))
                    }
                }
                task.resume()
            }
        }
    }
    
    
    /// Asynchronously obtain a webhook available by product or account by the webhook id
    ///
    /// This method will invoke authenticate with validateToken = false.  Any authentication error will be returned
    /// if not successful
    ///
    /// - parameter webhookID: the unique identifier of the webhook to fetch
    /// - parameter productIdOrSlug: Product ID or slug (only for product webhooks)
    /// - parameter completion: completion handler. Contains an array of Webhook objects
    public func webhook(_ webhookID: String, productIdOrSlug: String? = nil, completion: @escaping (Result<Webhook>) -> Void ) {
        
        self.authenticate(false) { (result) in
            switch (result) {
                
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                var request = URLRequest(url: productIdOrSlug != nil ? self.baseURL.appendingPathComponent("v1/products/\(String(describing: productIdOrSlug))/webhooks/\(webhookID)") : self.baseURL.appendingPathComponent("v1/webhooks/\(webhookID)"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Get a webhook \(webhookID)", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.webhookListFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let j = json, let j2 = j["webhook"] as? Dictionary<String,Any>, let webhook = Webhook(with: j2) {
                        return completion(.success(webhook))
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        warn("failed to get webhook \(webhookID) with response: \(String(describing: response)) and message body \(message)")
                        return completion(.failure(ParticleError.webhookGetFailed(webhookID, ParticleError.httpReponseParseFailed(message))))
                    }
                }
                task.resume()
            }
        }
    }
    
    /// Asynchronously obtain the webhooks available by product or account
    ///
    /// This method will invoke authenticate with validateToken = false.  Any authentication error will be returned
    /// if not successful
    ///
    /// - parameter productIdOrSlug: Product ID or slug (only for product webhooks)
    /// - parameter completion: completion handler. Contains an array of Webhook objects
    public func webhooks(productIdOrSlug: String? = nil, completion: @escaping (Result<[Webhook]>) -> Void ) {
        
        self.authenticate(false) { (result) in
            switch (result) {
                
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                var request = URLRequest(url: productIdOrSlug != nil ? self.baseURL.appendingPathComponent("v1/products/\(String(describing: productIdOrSlug))/webhooks") : self.baseURL.appendingPathComponent("v1/webhooks"))
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
               
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Listing all webhooks", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.webhookListFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String : Any]],  let j = json {
                        return completion(.success(j.flatMap({ return Webhook(with: $0)})))
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        warn("failed to list all webhooks with response: \(String(describing: response)) and message body \(String(describing: message))")
                        return completion(.failure(ParticleError.webhookListFailed(ParticleError.httpReponseParseFailed(message))))
                    }
                }
                task.resume()
            }
        }
    }
}






