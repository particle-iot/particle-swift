// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2017 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

// TODO:  upload a library version and make a library version public

import Foundation

/// Representation of a library
public struct Library {
    
    /// The unique identifier of the library
    public var id: String
    
    /// The URL to download the library
    public var linkDownload: URL
    
    /// The type of libraries.  Typically "libraries"
    public var type: String?
    
    /// Dictionary of optional attributes that describe the library.  Example value can be found at
    /// https://docs.particle.io/reference/api/#get-library-details
    public var attributes: [String : Any]?
    
    /// Optionally creates a Library instance from the specified dictionary.
    /// - dictionary: dictionary representation of the library
    ///
    /// Returns nil if the required keys are not in the dictionary
    init?(dictionary: [String: Any]) {
        
        guard let id = dictionary["id"] as? String,
            let linkDownload1 = dictionary["links"] as? [String : Any],
            let linkDownload2 = linkDownload1["download"] as? String,
            let linkDownload = URL(string: linkDownload2) else {
                return nil
        }
        
        self.id = id
        self.linkDownload = linkDownload
        self.attributes = dictionary["attributes"] as? [String : Any]
    }
    
    
    /// Which subset of libraries to list.
    ///
    /// - all: to retrieve public libraries and any private libraries belonging to the user
    /// - official: to retrieve official public libraries
    /// - `public`:  to retrieve public libraries
    /// - mine: to retrieve only public libraries belonging to the current user
    /// - `private`: to retrieve only private libraries (belonging to the current user).
    public enum Scope: String {
        case all
        case official
        case `public`
        case mine
        case `private`
    }
    
    /// Sort criteria used when requesting libraries
    ///
    /// - name: The name of the library
    /// - installs: The number of library installations
    /// - popularity: The popularity of the library
    /// - published: The publish date of the library
    /// - updated: The last updated date of the library
    /// - created: The creation date of the library
    /// - official: The official status of the library
    /// - verified: The verified status of the library
    public enum Sort: String {
        case name
        case installs
        case popularity
        case published
        case updated
        case created
        case official
        case verified
    }
    
    /// Defines the order of results returned base on the sort
    ///
    /// - ascending: Use ascending order
    /// - descending: Use descending order
    public enum SortOrder: String {
        case ascending = ""
        case descending = "-"
    }
}

// MARK: Libraries
extension ParticleCloud {
    
    /// Obtain a list of firmware libraries.  This includes retrieving private libraries visible only to the user
    ///
    /// - Parameters:
    ///   - scope: Which subset of libraries to list.
    ///   - matching: Search for libraries with this partial name
    ///   - page: Page number (first page is # 1)
    ///   - limit: Items per page (max 100)
    ///   - sortedBy:  The criteria used to sort results
    ///   - sortOrder: The sort order used in results
    ///   - excluding: Which subsets of libraries to avoid listing, separated by comma
    ///   - architectures: Architectures to list, separated by comma. Nil means all architectures.
    ///   - completion: completion handler containing the results of the request
    public func libraries(of scope: Library.Scope = .all, matching filter: String? = nil, page: Int = 1, limit: Int = 10, sortedBy: Library.Sort = .popularity, sortOrder: Library.SortOrder = .ascending, excluding: [Library.Scope] = [], architectures: String? = nil, completion: @escaping (Result<[Library]>) -> Void ) {
        
        self.authenticate(false) { result in
            switch result {
                
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                
                var url = self.baseURL.appendingPathComponent("v1/libraries")
                if filter != nil, !filter!.isEmpty {
                    url = url.appendingPathComponent("/\(filter!.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed))")
                }
                
                var urlComps = URLComponents(url: url, resolvingAgainstBaseURL: false)
                
                var queryItems = [URLQueryItem]()
                queryItems.append(URLQueryItem(name: "scope", value: scope.rawValue))
                queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
                queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
                queryItems.append(URLQueryItem(name: "sort", value: "\(sortOrder.rawValue)\(sortedBy.rawValue)"))
                if !excluding.isEmpty {
                    let value = excluding.map({ $0.rawValue }).joined(separator: ",")
                    queryItems.append(URLQueryItem(name: "excludeScopes", value: value))
                }
                if let architectures = architectures, !architectures.isEmpty {
                    queryItems.append(URLQueryItem(name: "architectures", value: architectures))
                }
                urlComps?.queryItems = queryItems

                guard let finalUrl = urlComps?.url else {
                    return completion(.failure(ParticleError.librariesUrlMalformed(String(describing: urlComps))))
                }
                
                var request = URLRequest(url: finalUrl)
                
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace("requesting libraries", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.librariesRequestFailed(String(describing: error))))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let j = json, let resultData = j["data"] as? [[String : Any]] {
                        var results: [Library] = []
                        results = resultData.flatMap { return Library(dictionary: $0) }
                        completion(.success(results))
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        warn("failed to obtain libraries with response: \(String(describing: response)) and message body \(message)")
                        return completion(.failure(ParticleError.librariesRequestFailed(message)))
                    }
                }
                task.resume()
            }
        }
    }
    
    /// Obtain a list of firmware library versions.
    ///
    /// - Parameters:
    ///   - named: The name (id) of the library
    ///   - scope: Which subset of library versions to list.
    ///   - completion: completion handler containing the results of the request
    public func libraryVersions(named name: String, of scope: Library.Scope = .all, completion: @escaping (Result<[Library]>) -> Void ) {
        
        self.authenticate(false) { result in
            switch result {
                
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                
                let url = self.baseURL.appendingPathComponent("v1/libraries/\(name)/versions")
                var urlComps = URLComponents(url: url, resolvingAgainstBaseURL: false)
                
                var queryItems = [URLQueryItem]()
                queryItems.append(URLQueryItem(name: "scope", value: scope.rawValue))
                urlComps?.queryItems = queryItems
                
                guard let finalUrl = urlComps?.url else {
                    return completion(.failure(ParticleError.libraryVersionsRequestFailed(String(describing: urlComps))))
                }

                var request = URLRequest(url: finalUrl)
                
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace("requesting library versions", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.libraryVersionsRequestFailed(String(describing: error))))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let j = json, let resultData = j["data"] as? [[String : Any]] {
                        var results: [Library] = []
                        results = resultData.flatMap { return Library(dictionary: $0) }
                        completion(.success(results))
                    } else {
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        warn("failed to obtain library versions with response: \(String(describing: response)) and message body \(message)")
                        return completion(.failure(ParticleError.libraryVersionsRequestFailed(message)))
                    }
                }
                task.resume()
            }
        }
    }
}

