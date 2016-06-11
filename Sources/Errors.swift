// This source file is part of the ParticleSwift open source project
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See https://github.com/vakoc/particle-swift/blob/master/LICENSE for license information

import Foundation

public enum ParticleError: ErrorProtocol {
    case MissingCredentials,
    ListAccessTokensFailed(ErrorProtocol),
    DeviceListFailed(ErrorProtocol),
    DeviceInformationFailed(String, ErrorProtocol),
    OAuthTokenCreationFailed(ErrorProtocol)
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
            return String.localizedStringWithFormat("Faield to create an OAuth token with error %1@", "\(error)")
        }
    }
}
