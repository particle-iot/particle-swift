// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation

public enum ParticleError: ErrorProtocol {
    case MissingCredentials,
    ListAccessTokensFailed(ErrorProtocol),
    DeviceListFailed(ErrorProtocol),
    DeviceInformationFailed(String, ErrorProtocol),
    OAuthTokenCreationFailed(ErrorProtocol),
    InvalidURLRequest(ErrorProtocol)
}

extension ParticleError: CustomStringConvertible {
    
    public var description: String {
        switch (self) {
        case .MissingCredentials:
            return String.localizedStringWithFormat("Missing username or password credentials")
        case .ListAccessTokensFailed(let error):
            return String.localizedStringWithFormat("The request to list available access tokens failed with %1@", "\(error)")
        case .DeviceListFailed(let error):
            return String.localizedStringWithFormat("The request to obtain available devices failled with error %1@", "\(error)")
        case .DeviceInformationFailed(let deviceID, let error):
            return String.localizedStringWithFormat("The request to obtain device information for device ID %1@ failed with error %2@", deviceID, "\(error)")
        case .OAuthTokenCreationFailed(let error):
            return String.localizedStringWithFormat("Failed to create an OAuth token with error %1@", "\(error)")
        case .InvalidURLRequest(let error):
            return String.localizedStringWithFormat("Unable to create a valid URL request with error %1@", "\(error)")
        }
    }
}
