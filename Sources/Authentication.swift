// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information


import Foundation

/// Delegate protocol used to provide ParticleSwift with credentials storage
public protocol SecureStorage: class {
    
    func username(_ realm: String) -> String?
    func password(_ realm: String) -> String?
    func oauthClientId(_ realm: String) -> String?
    func oauthClientSecret(_ realm: String) -> String?
    func oauthToken(_ realm: String) -> OAuthToken?
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
    public init?(with dictionary: [String : AnyObject]) {
        guard let accessToken = dictionary["access_token"] as? String , !accessToken.isEmpty,
            let tokenType = dictionary["token_type"] as? String , !tokenType.isEmpty,
            let expiresIn = dictionary["expires_in"] as? Int,
            let refreshToken = dictionary["refresh_token"] as? String , !tokenType.isEmpty
        
        else {
            return nil
        }
        
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresIn = Double(expiresIn)
        self.refreshToken = refreshToken
        self.created = (dictionary["created_at"] as? String)?.dateWithISO8601String ?? Date()
    }
    
    public var expirationDate: Date {
        return self.created.addingTimeInterval(expiresIn)
    }
    
    public var description: String {
        return "OAuthToken[accessToken=\(accessToken), expires=\(self.expirationDate.description)]"
    }
    
    public var dictionary: [String : AnyObject] {
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
    
    public init?(dictionary: [String : AnyObject]) {
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

public protocol OAuthAuthenticatable: class, WebServiceCallable {
    
    var realm: String { get }
    
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
    func authenticate(_ validateToken: Bool, completion: (Result<String>) -> Void)
    
    /// Asynchronously creates an access token.  Credentials and OAuth keys are obtained from the secureStorage used to create the
    /// instance
    ///
    /// The completion callback will be on a background thread
    ///
    /// - parameter expiresIn: how many seconds the token will be valid for.  0 means forever.  short lived tokens are better for security
    /// - parameter expiresAt: the date at which the token should expire.
    /// - parameter completion: completion handler.  Contains a Result enum with the OAuthToken or error encountered
    func createOAuthToken(_ expiresIn: TimeInterval, expiresAt: Date?, completion: (Result<OAuthToken>) -> Void )
}



extension OAuthAuthenticatable {
    
    public func authenticate(_ validateToken: Bool, completion: (Result<String>) -> Void) {
        
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
    
    public func createOAuthToken(_ expiresIn: TimeInterval = 60*60*24*365, expiresAt: Date? = nil, completion: (Result<OAuthToken>) -> Void ) {
        
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
        
        var request = URLRequest(url: self.baseURL.appendingPathComponent("oauth/token"))
        
        request.setValue("Basic \(base64AuthCredentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = urlParams.URLEncodedParameters?.data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        
        let task = self.urlSession.dataTask(with: request) { (data, response, error) in
            
            trace( "Creating an OAuth token", request: request, data: data, response: response, error: error)
            
            if let error = error {
                return completion(.failure(ParticleError.oauthTokenCreationFailed(error)))
            }
            
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : AnyObject],  let j = json,
                let token = OAuthToken(with: j) {
                completion(.success(token))
            } else {
                let error = NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : NSLocalizedString("Failed to obtain an OAuth token", tableName: nil, bundle: Bundle(for: self.dynamicType), comment: "The http request to create an OAuthToken failed")])
                return completion(.failure(ParticleError.oauthTokenCreationFailed(error)))
            }
        }        
        task.resume()
    }
}

