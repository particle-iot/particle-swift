// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information


import Foundation

/// Delegate protocol used to provide ParticleSwift with credentials storage
///
/// The functions of this protocol take a realm as the parameter.  The realm is the domain
/// in which to obtain credentails.  Derivative products may reuse this protocol to enable 
/// OAuth credential handling for multiple backends
///
/// Clients interested only in ParticleSwift may either ignore this parameter or return values
/// only when the realm is equal to ParticleSwiftInfo.realm, or the literal value "ParticleSwift"
///
/// Particle swift will typically ask the secure storage for a valid OAuthToken.  If the token is
/// not provided it will begin the authentication process, which will subsequently ask for the 
/// username, password, client id, and client secret.  These will be used to create a new OAuth token
/// and, if successful, will be provided back to the secure storage through the update method.
///
/// The secure storage class should should securely persist any tokens it is given and provide them
/// when asked.  Failure to store/restore tokens can result in a significant number of new server
/// created tokens and significant performce slowdowns due to the number of network requests needed
/// for their creation.
///
public protocol SecureStorage: class {
   
    /// Return the username for the given realm
    /// - parameter realm: The realm (domain) to return results.  Ignore if only using ParticleSwift 
    /// - returns: the username, or nil if not available
    func username(_ realm: String) -> String?
    
    /// Return the password for the given realm
    /// - parameter realm: The realm (domain) to return results.  Ignore if only using ParticleSwift
    /// - returns: the password, or nil if not available
    func password(_ realm: String) -> String?
    
    /// Return the OAuth client id for the given realm
    /// - parameter realm: The realm (domain) to return results.  Ignore if only using ParticleSwift
    /// - returns: the OAuth client id, or nil if not available
    func oauthClientId(_ realm: String) -> String?
    
    /// Return the OAuth client secret for the given realm
    /// - parameter realm: The realm (domain) to return results.  Ignore if only using ParticleSwift
    /// - returns: the OAuth client secret, or nil if not available
    func oauthClientSecret(_ realm: String) -> String?
    
    /// Return the persisted OAuth token for a given ealm
    /// - parameter realm: The realm (domain) to return results.  Ignore if only using ParticleSwift
    /// - returns: the OAUth token, or nil if not available
    func oauthToken(_ realm: String) -> OAuthToken?
    
    /// Save the specified token for the given realm
    /// - parameter realm: The realm (domain) to return results.  Ignore if only using ParticleSwift
    /// - returns: the OAuth token, or nil if not available
    func updateOAuthToken(_ token: OAuthToken?, forRealm realm: String)
}

/// Represents an OAuthToken as returned by the oauth/token
public struct OAuthToken: CustomStringConvertible, StringKeyedDictionaryConvertible {
    
    /// the magical token you will use for all other requests
    public var accessToken: String
    
    /// the token type, e.g. bearer
    public var tokenType: String
    
    /// the number of seconds this token is valid for.  0 means forever
    public var expiresIn: TimeInterval
    
    /// used to generate a new access token when it has expired
    public var refreshToken: String
    
    /// the time the structure was created
    public let created: Date
    
    /// Creates an OAuth token from a string keyed dictionary as returned by /oauth/token
    ///
    /// If any of the required properties are not found it returns nil
    /// - parameter dictionary: the key/value definition of the token to parse
    public init?(with dictionary: [String : Any]) {
        guard let accessToken = dictionary["access_token"] as? String , !accessToken.isEmpty,
            let tokenType = dictionary["token_type"] as? String , !tokenType.isEmpty,
            let expiresIn = dictionary["expires_in"] as? CustomStringConvertible,
            let expiresInInt = Int("\(expiresIn)"),
            let refreshToken = dictionary["refresh_token"] as? String , !tokenType.isEmpty
        
        else {
            warn("failed to reconstitute and OAuth token with the dictionary \(dictionary)")
            return nil
        }
        
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresIn = TimeInterval(expiresInInt)
        self.refreshToken = refreshToken
        self.created = (dictionary["created_at"] as? String)?.dateWithISO8601String ?? Date()
    }
    
    /// The date the token expires
    public var expirationDate: Date {
        return self.created.addingTimeInterval(expiresIn)
    }
    
    /// Textual description of the token
    public var description: String {
        return "OAuthToken[accessToken=\(accessToken), expires=\(self.expirationDate.ISO8601String)]"
    }
    
    /// Dictionary represenation of the token, suitable for serialization
    public var dictionary: [String : Any] {
        return ["access_token" : accessToken, "token_type" : self.tokenType, "expires_in" : self.expiresIn, "refresh_token" : self.refreshToken, "created_at" : self.created.ISO8601String]
    }
    
}

/// Represents an OAuthToken as returned by the access_tokens
public struct OAuthTokenListEntry: CustomStringConvertible {
    
    /// the magical token you will use for all other requests
    public var accessToken: String
    
    /// The date the token expires
    public var expires: Date
    
    /// the client string
    public var client: String
    
    public init?(dictionary: [String : Any]) {
        guard let accessToken = dictionary["token"] as? String , !accessToken.isEmpty,
            let client = dictionary["client"] as? String , !client.isEmpty,
            let expires = dictionary["expires_at"] as? String,
            let expiresAt = expires.dateWithISO8601String
            else {
                return nil
        }
        
        self.accessToken = accessToken
        self.client = client
        self.expires = expiresAt
    }
    
    
    public var description: String {
        return "OAuthTokenListEntry[accessToken=\(accessToken), expires=\(expires), client=\(client)]"
    }
}

/// Abstraction for services that provide OAuth based uathentication.  OAuthAutheticable are objects
/// that can request, process, and use credentials to validate or create OAuth tokens and store them
/// for subsequent use
public protocol OAuthAuthenticatable: class, WebServiceCallable {
    
    /// The realm for authentication.  Used to enable multiple OAuth providers out of a single secure storage provider
    var realm: String { get }
    
    /// The secure storage provider used to provide/persist credentails on a per realm instance
    var secureStorage: SecureStorage? { get }
        
    /// Performs authentication asynchronously returning the access token to utilize
    ///
    /// Authentication is not necessarily an online endeavor.  The flow will ask the secure storage
    /// delegate for an OAuthToken.  If found and the expiration date is greater than now
    /// the accessToken will be returned unless the validate option is true (see below)
    ///
    /// If the secure storage returned an OAuthToken and validate is true the access_tokens method
    /// will be invoked using that access token to validate.  If the request is denied or the token
    /// isn't in the list (which shouldn't ever be the case) the logic will fall into the username/password
    /// logic below
    ///
    /// If secure storage returned valid appearing token and validate is true but the authentication failed
    /// for some reason other than auth failure (such as no network) the UnableToValidateToken(accessToken)
    /// failure result will be returned.  The token may (and probably is) valid and the caller may choose to use it.
    ///
    /// If no OAuthToken is provided by the secure storage or valdiation is enabled but validation failed
    /// the logic will invoke createOAuthToken to attempt to create a no oauth token.  If unsuccessful the
    /// failure returned by createOAuthToken will be returned.  If this call succeeds the OAuthToken setter on
    /// the secure storage delegate will be called to store the result for future calls.
    ///
    /// If successful based on all the above the result the accessToken to use will be returned
    ///
    /// The completion callback will be on a background thread
    ///
    /// - TODO: handle refresh_token for non particle oauth tokens (See https://community.particle.io/t/how-to-use-the-refresh-token/15889/6)
    ///
    /// - parameter validateToken: if true perform an online validation of any token obtained from secure storage
    /// - parameter completion: the completion block to be called.  will always be asynchronous and on a background thread
    func authenticate(_ validateToken: Bool, completion: @escaping (Result<String>) -> Void)
    
    /// Asynchronously creates an access token.  Credentials and OAuth keys are obtained from the secureStorage used to create the
    /// instance
    ///
    /// The completion callback will be on a background thread
    ///
    /// - parameter expiresIn: how many seconds the token will be valid for.  0 means forever.  short lived tokens are better for security
    /// - parameter expiresAt: the date at which the token should expire.
    /// - parameter completion: completion handler.  Contains a Result enum with the OAuthToken or error encountered
    func createOAuthToken(_ expiresIn: TimeInterval, expiresAt: Date?, completion: @escaping (Result<OAuthToken>) -> Void )
}



extension OAuthAuthenticatable {
    
    public func authenticate(_ validateToken: Bool, completion: @escaping (Result<String>) -> Void) {
        
        if let token = secureStorage?.oauthToken(self.realm) , Date().compare(token.expirationDate as Date) == ComparisonResult.orderedAscending {
            if !validateToken {
                return dispatchQueue.async { completion(.success(token.accessToken)) }
            }
            
            /// TODO validate the token to ensure it doesn't suck
            return dispatchQueue.async { completion(.success(token.accessToken)) }
        }
        
        /// TODO:  parameterize the expiresIn
        self.createOAuthToken(60*60*7, expiresAt: nil) { (createOAuthTokenResult) in
            switch (createOAuthTokenResult) {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let token):
                self.secureStorage?.updateOAuthToken(token, forRealm: self.realm)
                completion(.success(token.accessToken))
            }
        }
    }
    
    public func createOAuthToken(_ expiresIn: TimeInterval = 60*60*24*365, expiresAt: Date? = nil, completion: @escaping (Result<OAuthToken>) -> Void ) {
        
        guard let username = secureStorage?.username(self.realm), let password = secureStorage?.password(self.realm), let OAuthClientID = secureStorage?.oauthClientId(self.realm), let OAuthClientSecret = secureStorage?.oauthClientSecret(self.realm) else {
            return dispatchQueue.async { completion(.failure(ParticleError.missingCredentials)) }
        }
        
        var urlParams: [String : String] = ["grant_type" : "password", "username" : username, "password" : password, "expires_in" : "\(Int(expiresIn))"]
        
        if let date = expiresAt {
            urlParams["expires_at"] = date.ISO8601String
        }
        
        let basicAuthCredentials = "\(OAuthClientID):\(OAuthClientSecret)"
        guard let data = basicAuthCredentials.data(using: String.Encoding.utf8) else {
            return
        }
        
        let base64AuthCredentials = data.base64EncodedString(options: [])
        
        var requesta = URLRequest(url: self.baseURL.appendingPathComponent("oauth/token"))
        
        requesta.setValue("Basic \(base64AuthCredentials)", forHTTPHeaderField: "Authorization")
        requesta.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        requesta.httpBody = urlParams.URLEncodedParameters?.data(using: String.Encoding.utf8)
        requesta.httpMethod = "POST"

	// Work around a compiler crash bug on Linux by preventing the capture of a mutable variable by ref
        // and simply capture a let instead
	let request = requesta
        
        let task = self.urlSession.dataTask(with: request) { (data, response, error) in
            
            trace( "Creating an OAuth token", request: request, data: data, response: response, error: error)
            
            if let error = error {
                return completion(.failure(ParticleError.oauthTokenCreationFailed(error)))
            }
            
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],  let j = json,
                let token = OAuthToken(with: j) {
                completion(.success(token))
            } else {
                return completion(.failure(ParticleError.oauthTokenCreationFailed(ParticleError.oauthTokenParseFailed)))
            }
        }        
        task.resume()
    }
}

