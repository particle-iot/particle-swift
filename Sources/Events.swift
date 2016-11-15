// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation

extension Notification.Name {
    
    /// Notification emitted when a particle event occurs
    public static let ParticleEvent = Notification.Name("ParticleEventNotification")
}


/// Event source that monitors and notifies on events emitted by monitored devices
///
/// Particle Cloud event urls follow the Server-Sent Events spec (http://www.w3.org/TR/eventsource/)
///
/// Event sources are based on a single URL and are authenticated using an access token specified
/// at the time of creation.  Event sources may be started and stopped repeatedly though they are
/// useful only for the lifetime of the access token provided
public class EventSource: NSObject {
    
    /// The key in the user info of the Notification.Name.ParticleEvent containing the actual Event
    public static let ParticleEventKey = "ParticleEventKey"
    
    
    /// Represents an event received from an EventSource (Particle Cloud)
    public struct Event {
        
        /// The name of the event
        public let name: String
        
        /// the date the event was published
        public let published: Date
        
        /// ttl
        public let ttl: Int
        
        /// The identifier of the core
        public let coreid: String
        
        /// Data associated with the event
        public let data: String?
        
        /// JSON representation of the event
        public var jsonRepresentation: Dictionary<String,Any> {
            var ret = [String : Any]()
            ret["name"] = name
            ret["published_at"] = published.ISO8601String
            ret["ttl"] = ttl
            ret["coreid"] = coreid
            if let data = data {
                ret["data"] = data
            }
            return ret
        }
        
        /// Create an event with the specified name and properties defined in a dictionary
        ///
        /// Returns nil if the event name is invalid or the dictionary does not contain
        /// all the required information
        ///
        /// - parameter name: the name of the event
        /// - parameter dictionary: the dictionary containing the required initialization properties
        fileprivate init?(name: String, dictionary: Dictionary<String,Any>) {
            
            guard !name.isEmpty, let dateString = dictionary["published_at"] as? String, let date = dateString.dateWithISO8601String,
                let ttl = dictionary["ttl"], let ttlInt = Int("\(ttl)"),
                let coreid = dictionary["coreid"]  else {
                    warn("Unable to create an Event with name \(name) and dictionary \(dictionary)")
                    return nil
            }
            
            self.name = name
            self.published = date
            self.ttl = ttlInt
            self.coreid = "\(coreid)"
            self.data = dictionary["data"] as? String
        }
    }
    
    /// The URL of the event emitter
    public let url: URL
    
    /// The authorization bearer for the request
    internal let token: String
    
    /// The URL session utilized for fetching events
    var urlSession: URLSession?
    
    /// String data of received data pending parsing.  Each report of data received may result in 
    /// incomplete parseable state;  any remaining unparsed bits are stored here
    internal var pendingString = ""
    
    /// The serial queue used to process incoming data streams
    lazy var queue: DispatchQueue = { DispatchQueue(label: "com.vakoc.EventSource", qos: .background, attributes: []) }()
    
    /// The state of an event source
    ///
    /// - stopped: Not actively receiving data
    /// - started: Actively receiving data
    public enum State {
        case stopped, started
    }
    
    /// The current state
    public internal(set) var state: State = .stopped
    
    /// The data task used to fetch data.  Valid only when the state == .started
    internal var task: URLSessionDataTask?
    
    /// Create a new event source
    ///
    /// - Parameters:
    ///   - url: The URL providing the server-sent events
    ///   - token: The access token to use for authorization;  assummed to be valid at the time of creation
    ///   - cloud: The particle cloud instance.  Used only to obtain the URLSessionConfiguration
    fileprivate init(with url: URL, token: String, cloud: ParticleCloud) {
        self.token = token
        self.url = url
        super.init()
        urlSession = URLSession(configuration: cloud.urlSession.configuration, delegate: self, delegateQueue: OperationQueue.main)

    }
    
    /// Connect and start emitting events
    public func start() {
        if task != nil { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        task = urlSession?.dataTask(with: request)
        task?.resume()
        
    }
    
    /// Stop any active url sessions and terminate sending events
    public func stop() {
        parseState = .pendingOK
        pendingString = ""
        task?.cancel()
        task = nil
    }
    
    /// Internal state used during the processing of the incoming HTTP messagew
    ///
    /// - pendingOK: awaiting the :ok token
    /// - pendingEventTag: awaiting the 'event: ' token
    /// - pendingEventName: awaiting the event name (newline terminated)
    /// - pendingData: awaiting the data: token
    /// - pendingDataPayload: awaiting the event data JSON payload (newline terminated)
    private enum ParseState {
        case pendingOK,
        pendingEventTag,
        pendingEventName,
        pendingData,
        pendingDataPayload
    }
    
    /// The current parser state
    private var parseState: ParseState = .pendingOK
    
    /// The name of the next event.  Set during .pendingEventName and cleared during .pendingEventTag states
    var nextEvent: NSString?
    
    /// Parse the incoming string.  The method should be invoked only within the context of the self.queue dispatch queue
    ///
    /// - Parameter string: the incoming string
    fileprivate func parse(_ string: String) {
        
        let scanner = Scanner(string: pendingString + string)
        var currentState = parseState
        repeat {
            currentState = parseState
            
            switch parseState {
            case .pendingOK:
                scanner.scanUpTo(":ok", into: nil)
                if  scanner.scanString(":ok", into: nil) {
                    scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil)
                    parseState = .pendingEventTag
                }
            case .pendingEventTag:
                scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil)
                nextEvent = nil
                if scanner.scanString("event: ", into: nil) {
                    scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil)
                    parseState = .pendingEventName
                }
            case .pendingEventName:
                scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil)
                if scanner.scanUpToCharacters(from: .newlines, into: &nextEvent) {
                    parseState = .pendingData
                }
            case .pendingData:
                scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil)
                if scanner.scanString("data:", into: nil) {
                    scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil)
                    parseState = .pendingDataPayload
                }
            case .pendingDataPayload:
                scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil)
                var json: NSString?
                if scanner.isNext(character: "{") && scanner.scanUpToCharacters(from: .newlines, into: &json) {
                    scanner.scanCharacters(from: .whitespacesAndNewlines, into: nil)
                    
                    parseState = .pendingEventTag
                    guard let json = json as? String else { break }
                    let data = json.data(using: .utf8)
                    if let nextEvent = nextEvent as? String, let data = data, let parsedJson = try? JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String,Any>, var j = parsedJson, let event = Event(name: nextEvent, dictionary: j) {
                        trace("Received event \(nextEvent) with payload \(parsedJson)")
                        j["name"] = nextEvent
                        NotificationCenter.default.post(name: .ParticleEvent, object: self, userInfo: [EventSource.ParticleEventKey : event])
                    }
                }
                break
            }
            pendingString = scanner.remainder
        } while parseState != currentState && !pendingString.isEmpty
    }
}

extension EventSource.Event: Equatable {
    
    public static func ==(lhs: EventSource.Event, rhs: EventSource.Event) -> Bool {
        return lhs.name == rhs.name &&
            lhs.published == rhs.published &&
            lhs.ttl == rhs.ttl &&
            lhs.coreid == rhs.coreid &&
            lhs.data == rhs.data
    }
}


extension EventSource: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        // TODO:  validate encoding from data headers and not assume 
        // utf-8 (proxies, in particular, can manipulate and we can't assume what particle provices is final)
        guard let string = String(data: data, encoding: .utf8), !string.isEmpty else {
            return
        }
        queue.async { [weak self] in
            self?.parse(string)
        }
    }
}

extension ParticleCloud {
    
    /// Create an event source
    ///
    /// Event sources are created only when a current access token is available.  No guarantees are made
    /// that the access token used to create the event source are still valid at the time the event source
    /// is used
    ///
    /// Event sources are created in the stopped state and must be started by invoking start()
    ///
    /// - Parameters:
    ///   - prefix: Optional filter that results in only the events that start with the specified value being included
    ///   - productIdOrSlug: The product id, for product events
    ///   - completion: Handler to call with the event source.  The completion handler is expected to strongly own any event source provided
    public func createEventSource(prefix: String? = nil, productIdOrSlug: String? = nil, completion: @escaping (Result<EventSource>) -> Void ) {
        
        self.authenticate(false) { result in
            switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let accessToken):
                    completion(.success(EventSource(with: self.baseURL.appendingPathComponent("v1/devices/events"), token: accessToken, cloud: self)))
            }
        }
    }
}
