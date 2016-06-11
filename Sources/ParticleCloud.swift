// This source file is part of the ParticleSwift open source project
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See https://github.com/vakoc/particle-swift/blob/master/LICENSE for license information


import Foundation

public let ParticleCloudRealm = "ParticleCloud"

/// The base for the particle URLs
public let kParticleDefaultURL = NSURL(string: "https://api.particle.io/")!

///
///
/// ParticleCloud methods are not generally stateful.  Beyond authentication, which itself is stateful
/// only in that it stores credentials thorugh the secure storage delegate, does not
/// 
public class ParticleCloud: WebServiceCallable {
    
    /// The base URL used to interact with particle.  Set during initialization
    public let baseURL: NSURL
    
    /// The OAuth realm    
    public var realm = ParticleCloudRealm
    
    /// the networking stack used for this particle instance
    public lazy var urlSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.default()
        let urlSession = NSURLSession(configuration: configuration)
        return urlSession
    }()
    
    /// the dispatch queue used to perform all opeartions for this cloud instance
    public var dispatchQueue: dispatch_queue_t = dispatch_queue_create("Particle", DISPATCH_QUEUE_CONCURRENT)
    
    /// provider for secure credentials
    public private(set) weak var secureStorage: SecureStorage?
    
    /// Create a new instance of the particle cloud interface
    ///
    /// Refer to https://docs.particle.io/guide/how-to-build-a-product/authentication/ for more information
    /// about the OAuth related bits
    /// https://docs.particle.io/reference/api/
    ///
    /// - parameter baseURL: the base url to use, defaults to kParticleDefaultURL
    /// - parameter secureStorage: provider of credentials
    public init(baseURL:NSURL = kParticleDefaultURL, secureStorage: SecureStorage?) {
        self.baseURL = baseURL
        self.secureStorage = secureStorage
    }
    
    /// Asynchronously lists the access tokens associated with the account
    ///
    /// This mmethod will invoke authenticate with validateToken = false.  Any authentication error will be returned    
    /// - parameter completion: completion handler. Contains a list of oauth tokens
    public func accessTokens(completion: (Result<[OAuthTokenListEntry]>) -> Void ) {
        
        let request = NSURLRequest(url: self.baseURL.appendingPathComponent("v1/access_tokens")).mutableCopy() as! NSMutableURLRequest
        
        guard let username = self.secureStorage?.username(realm: self.realm), let password = self.secureStorage?.password(realm: self.realm) else {
            dispatch_async(self.dispatchQueue) {
                completion(.Failure(ParticleError.MissingCredentials))
            }
            return
        }
        
        guard let data = "\(username):\(password)".data(using: NSUTF8StringEncoding) else {
            return dispatch_async(dispatchQueue) { completion(.Failure(ParticleError.MissingCredentials)) }
        }
        
        let base64AuthCredentials = data.base64EncodedString([])
        request.setValue("Basic \(base64AuthCredentials)", forHTTPHeaderField: "Authorization")

        let task = self.urlSession.dataTask(with: request) { (data, response, error) in
            
            trace(description: "Get access tokens", request: request, data: data, response: response, error: error)
            
            if let error = error {
                return completion(.Failure(ParticleError.ListAccessTokensFailed(error)))
            }
            
            if let data = data, json = try? NSJSONSerialization.jsonObject(with: data, options: []) as? [[String : AnyObject]],  j = json {
                return completion(.Success(j.flatMap() { return OAuthTokenListEntry(dictionary: $0)} ))
            } else {
                let error = NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed to obtain access token lists", tableName: nil, bundle: NSBundle(for: self.dynamicType), comment: "The http request to create an OAuthToken failed")])
                return completion(.Failure(ParticleError.ListAccessTokensFailed(error)))
            }
        }
        task.resume()
    }
}

extension ParticleCloud: OAuthAuthenticatable {

    

}

extension ParticleCloud: CustomStringConvertible {
    
     public var description: String {
        return "\(secureStorage?.username) -- \(secureStorage?.oauthClientId)"
    }
}