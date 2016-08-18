// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information


import Foundation




/// The base for the particle URLs
public let kParticleDefaultURL = URL(string: "https://api.particle.io/")!

///
///
/// ParticleCloud methods are not generally stateful.  Beyond authentication, which itself is stateful
/// only in that it stores credentials thorugh the secure storage delegate, does not
/// 
public class ParticleCloud: WebServiceCallable {
    
    /// The base URL used to interact with particle.  Set during initialization
    public let baseURL: URL
    
    /// The OAuth realm    
    public var realm = ParticleSwiftInfo.realm
    
    /// the networking stack used for this particle instance
    public lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
    
    /// the dispatch queue used to perform all opeartions for this cloud instance
    public var dispatchQueue = DispatchQueue(label: "Particle", attributes: [.concurrent])
    
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
    public init(baseURL:URL = kParticleDefaultURL, secureStorage: SecureStorage?) {
        self.baseURL = baseURL
        self.secureStorage = secureStorage
    }
    
    /// Asynchronously lists the access tokens associated with the account
    ///
    /// This mmethod will invoke authenticate with validateToken = false.  Any authentication error will be returned    
    /// - parameter completion: completion handler. Contains a list of oauth tokens
    public func accessTokens(_ completion: @escaping (Result<[OAuthTokenListEntry]>) -> Void ) {
        
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/access_tokens"))
        
        
        guard let username = self.secureStorage?.username(self.realm), let password = self.secureStorage?.password(self.realm) else {
            self.dispatchQueue.async  {
                completion(.failure(ParticleError.missingCredentials))
            }
            return
        }
        
        guard let data = "\(username):\(password)".data(using: String.Encoding.utf8) else {
            return dispatchQueue.async  { completion(.failure(ParticleError.missingCredentials)) }
        }
        
        let base64AuthCredentials = data.base64EncodedString(options: [])
        request.setValue("Basic \(base64AuthCredentials)", forHTTPHeaderField: "Authorization")
        let task = urlSession.dataTask(with: request, completionHandler:  { (data, response, error) in
            
            trace( "Get access tokens", request: request, data: data, response: response, error: error as NSError? )
            
            if let error = error {
                return completion(.failure(ParticleError.listAccessTokensFailed(error)))
            }
            
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String : AnyObject]],  let j = json {
                return completion(.success(j.flatMap() { return OAuthTokenListEntry(dictionary: $0)} ))
            } else {
                let error = NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed to obtain access token lists", tableName: nil, bundle: Bundle(for: type(of: self)), comment: "The http request to create an OAuthToken failed")])
                return completion(.failure(ParticleError.listAccessTokensFailed(error)))
            }
        })
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
