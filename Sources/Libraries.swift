

// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2017 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information


import Foundation

public struct Library {
    
}



// MARK: Libraries
extension ParticleCloud {
    
    
    
    public func libraries(completion: @escaping (Result<[Library]>) -> Void ) {
        
        self.authenticate(false) { result in
            switch result {
                
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/libraries"))
                
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace("requesting libraries", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.createWebhookFailed(error)))
                    }
                    
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any], let j = json {
                        
                        completion(.success([]))
                        
                        //                        if j.bool(for: "ok") == true {
                        //                            trace("Successfully invoked compilation of \(files.count) file(s) with result \(j)")
                        //
                        //                            guard let binary_id = j["binary_id"] as? String,
                        //                                let binary_url = j["binary_url"] as? String,
                        //                                let expires_at = j["expires_at"] as? String,
                        //                                let expires = expires_at.dateWithISO8601String,
                        //                                let size_info = j["sizeInfo"] as? String else {
                        //
                        //                                    let message = String(data: data, encoding: String.Encoding.utf8) ?? ""
                        //                                    warn("failed to receive expected compile result with response: \(String(describing: response)) and message body \(message)")
                        //                                    return completion(.failure(ParticleError.compileRequestFailed(message)))
                        //                            }
                        //
                        //                            let buildResult = BinaryInfo(binaryId: binary_id, binaryUrl: binary_url, expires: expires, sizeInfo: size_info)
                        //                            completion(.success([]))
                        //                        } else {
                        //                            let result: BuildResult = .compileFailure(output: j["output"] as? String ?? "", stdout: j["stdout"] as? String ?? "", errors: j["errors"] as? [String] ?? [])
                        //                            completion(.success(result))
                        //                        }
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        warn("failed to obtain libraries response: \(String(describing: response)) and message body \(message)")
                        return completion(.failure(ParticleError.librariesRequestFailed(message)))
                    }
                }
                task.resume()
            }
        }
    }
}

