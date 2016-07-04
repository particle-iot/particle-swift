// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation
import VakocLogging

public enum ParticleError: ErrorProtocol {
    case missingCredentials,
    listAccessTokensFailed(ErrorProtocol),
    deviceListFailed(ErrorProtocol),
    deviceInformationFailed(String, ErrorProtocol),
    oauthTokenCreationFailed(ErrorProtocol),
    invalidURLRequest(ErrorProtocol),
    claimDeviceFailed(ErrorProtocol),
    transferDeviceFailed(ErrorProtocol)
}

extension ParticleError: CustomStringConvertible {
    
    public var description: String {
        switch (self) {
        case .missingCredentials:
            return String.localizedStringWithFormat("Missing username or password credentials")
        case .listAccessTokensFailed(let error):
            return String.localizedStringWithFormat("The request to list available access tokens failed with %1@", "\(error)")
        case .deviceListFailed(let error):
            return String.localizedStringWithFormat("The request to obtain available devices failled with error %1@", "\(error)")
        case .deviceInformationFailed(let deviceID, let error):
            return String.localizedStringWithFormat("The request to obtain device information for device ID %1@ failed with error %2@", deviceID, "\(error)")
        case .oauthTokenCreationFailed(let error):
            return String.localizedStringWithFormat("Failed to create an OAuth token with error %1@", "\(error)")
        case .invalidURLRequest(let error):
            return String.localizedStringWithFormat("Unable to create a valid URL request with error %1@", "\(error)")
        case .claimDeviceFailed(let error):
            return String.localizedStringWithFormat("Unable to claim device with error %1@", "\(error)")
        case .transferDeviceFailed(let error):
            return String.localizedStringWithFormat("Unable to transfer device with error %1@", "\(error)")
        }
    }
}
