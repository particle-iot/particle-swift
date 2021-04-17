// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2017 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information


import Foundation


/// Representation of a compilable source file
public struct SourceFile {
    
    /// Create a new source file with the specified contents
    ///
    /// - Parameters:
    ///   - name: The name of the file.  May include path separators
    ///   - contents: The source file content, in utf8
    public init(name: String, contents: Data) {
        self.name = name
        self.contents = contents
    }
    
    /// The name of the source file.  May include relative paths, such as `include/header.h`
    public let name: String
    
    /// The contents in the source file, in UTF-8 encoding
    public let contents: Data
}

/// Detail of a binary produced by a successfull compilation
public struct BinaryInfo {
    
    /// The unique identifier of the binary
    public let binaryId: String
    
    /// The url used to access the binary
    public let binaryUrl: String
    
    /// The expiration date for the binary
    public let expires: Date
    
    /// Information about the size of the binary
    public let sizeInfo: String
    
}

/// The result of a compilation web service invocation. 
///
/// A distinction is made between failures.  Any successful invocation of the webservice will result
/// in this enum being returned.  The enum values dictate whether a
///
/// - compileSuccess: A successful compilation.  The associated value is a BinaryInfo structure
/// - compileFailure: The sources failed to compiled.  Associated values include output, stdout, and errors
public enum BuildResult {
    case compileSuccess(BinaryInfo)
    case compileFailure(output: String, stdout: String, errors: [String])
}


// MARK: Firmware
extension ParticleCloud {
    

    /// Compile the specified source files for a given device and product.
    ///
    /// Note the completion callback result indicates only whether the web service invocation was successful.
    /// On successful web service invocation the returned BuildResult must be evaluted to determine whether 
    /// the compilation was successful
    ///
    /// - Parameters:
    ///   - files: The fiels to compile
    ///   - deviceID: The identifier of the device to target
    ///   - product: The product to build for
    ///   - build_target_version: The firmware version to compile against. nil defaults to latest
    ///   - completion: the callback for the asynchronous operation
    public func compile(_ files: [SourceFile], for deviceID: String, product: DeviceInformation.Product, targeting build_target_version: String? = nil, completion: @escaping (Result<BuildResult>) -> Void ) {
        
        self.authenticate(false) { result in
            switch result {
                
            case .failure(let error):
                return completion(.failure(error))
                
            case .success(let accessToken):
                var request = URLRequest(url: self.baseURL.appendingPathComponent("v1/binaries"))
                
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.httpMethod = "POST"
                
                let boundary = UUID().uuidString
                
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                var body = String()
                
                // Insert the product id
                body += "--\(boundary)\r\n"
                body += "Content-Disposition: form-data; name=\"product_id\"\r\n\r\n"
                body += "\(product)\r\n"
                
                if let build_target_version = build_target_version {
                    body += "--\(boundary)\r\n"
                    body += "Content-Disposition: form-data; name=\"build_target_version\"\r\n\r\n"
                    body += "\(build_target_version)\r\n"
                }
                
                for (index,file) in  files.enumerated() {
                    
                    guard let fileContent = String(data: file.contents, encoding: .utf8) else { continue }
                    
                    body += "--\(boundary)\r\n"
                    body += "Content-Disposition: form-data; name=\"file\(index+1)\"; filename=\"\(file.name)\"\r\n\r\n"

                    body += fileContent
                    body += "\r\n"
                }
                body += "--\(boundary)--\r\n"
                
                trace("compile message body:\n\n\(body)\n\n")
                
                request.httpBody = body.data(using: .utf8)
                
                let task = self.urlSession.dataTask(with: request) { (data, response, error) in
                    
                    trace( "Compiled \(files.count) files", request: request, data: data, response: response, error: error)
                    
                    if let error = error {
                        return completion(.failure(ParticleError.createWebhookFailed(error)))
                    }
                    
                    if let data = data, let j = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                        
                        if j.bool(for: "ok") == true {
                            trace("Successfully invoked compilation of \(files.count) file(s) with result \(j)")
                            
                            guard let binary_id = j["binary_id"] as? String,
                                let binary_url = j["binary_url"] as? String,
                                let expires_at = j["expires_at"] as? String,
                                let expires = expires_at.dateWithISO8601String,
                                let size_info = j["sizeInfo"] as? String else {
                                    
                                    let message = String(data: data, encoding: String.Encoding.utf8) ?? ""
                                    warn("failed to receive expected compile result with response: \(String(describing: response)) and message body \(message)")
                                    return completion(.failure(ParticleError.compileRequestFailed(message)))
                            }
                            
                            let buildResult = BinaryInfo(binaryId: binary_id, binaryUrl: binary_url, expires: expires, sizeInfo: size_info)
                            completion(.success(.compileSuccess(buildResult)))
                        } else {
                            let result: BuildResult = .compileFailure(output: j["output"] as? String ?? "", stdout: j["stdout"] as? String ?? "", errors: j["errors"] as? [String] ?? [])
                            completion(.success(result))
                        }
                    } else {
                        
                        let message = data != nil ? String(data: data!, encoding: String.Encoding.utf8) ?? "" : ""
                        warn("failed to compile sources with response: \(String(describing: response)) and message body \(message)")
                        return completion(.failure(ParticleError.compileRequestFailed(message)))
                    }
                }
                task.resume()
            }
        }
    }
}
