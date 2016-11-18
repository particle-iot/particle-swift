// This source file is part of the vakoc.com open source project(s)
//
// Copyright © 2016 Mark Vakoc. All rights reserved.
// Licensed under Apache License v2.0
//
// See http://www.vakoc.com/LICENSE.txt for license information

import Foundation

/// Errors that can be thrown during particle operations
public enum ParticleError: Error {
    case missingCredentials,
    listAccessTokensFailed(Error),
    callFunctionFailed(Error),
    deviceListFailed(Error),
    deviceInformationFailed(String, Error),
    oauthTokenCreationFailed(Error),
    invalidURLRequest(Error),
    claimDeviceFailed(Error),
    transferDeviceFailed(Error),
    createClaimCode(Error),
    unclaimDeviceFailed(Error),
    webhookListFailed(Error),
    webhookGetFailed(String,Error),
    createWebhookFailed(Error),
    failedToParseJsonFile,
    deleteWebhookFailed(String,Error)
}

// Linux doesn't support variadic lists including strings, reference https://bugs.swift.org/browse/SR-957

#if os(Linux)
    
    extension ParticleError: CustomStringConvertible {
        
        public var description: String {
            switch (self) {
            case .missingCredentials:
                return "Missing username or password credentials"
            case .listAccessTokensFailed(let error):
                return "The request to list available access tokens failed with error \(error)"
            case .callFunctionFailed(let error):
                return "The request to call the function afiled with error \(error)"
            case .deviceListFailed(let error):
                return "The request to obtain available devices failled with error \(error)"
            case .deviceInformationFailed(let deviceID, let error):
                return "The request to obtain device information for device ID \(deviceID) failed with error \(error)"
            case .oauthTokenCreationFailed(let error):
                return "Failed to create an OAuth token with error \(error)"
            case .invalidURLRequest(let error):
                return "Unable to create a valid URL request with error \(error)"
            case .claimDeviceFailed(let error):
                return "Unable to claim device with error \(error)"
            case .transferDeviceFailed(let error):
                return "Unable to transfer device with error \(error)"
            case .createClaimCode(let error):
                return "Unable to create a claim code with error \(error)"
            case .unclaimDeviceFailed(let error):
                return "Unable to unclaim a device with error \(error)"
            case .webhookListFailed(let error):
                return "Unable to list the available webhooks with error \(error)"
            case .webhookGetFailed(let webhookID, let error):
                return "Unable to get the webhook \(webhookID) with error \(error)"
            case .createWebhookFailed(let error):
                return "Unable to create the webhook with error \(error)"
            case .failedToParseJsonFile:
                return "Unable to parse the specified JSON file"
            case .deleteWebhookFailed(let webhookID, let error):
                return "Unable to delete the webhook \(webhookID) with error \(error)"
            }
        }
    }
    
#else
    
    extension ParticleError: CustomStringConvertible {
        
        public var description: String {
            switch (self) {
            case .missingCredentials:
                return String.localizedStringWithFormat("Missing username or password credentials")
            case .listAccessTokensFailed(let error):
                return String.localizedStringWithFormat("The request to list available access tokens failed with error %1@", "\(error)")
            case .callFunctionFailed(let error):
                return String.localizedStringWithFormat("The request to call the function afiled with error %1@", "\(error)")
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
            case .createClaimCode(let error):
                return String.localizedStringWithFormat("Unable to create a claim code with error %1@", "\(error)")
            case .unclaimDeviceFailed(let error):
                return String.localizedStringWithFormat("Unable to unclaim a device with error %1@", "\(error)")
            case .webhookListFailed(let error):
                return String.localizedStringWithFormat("Unable to list the available webhooks with error %1@", "\(error)")
            case .webhookGetFailed(let webhookID, let error):
                return String.localizedStringWithFormat("Unable to get the webhook %1@ with error %2@", "\(webhookID)", "\(error)")
            case .createWebhookFailed(let error):
                return String.localizedStringWithFormat("Unable to create the webhook with error %1@", "\(error)")
            case .failedToParseJsonFile:
                return String.localizedStringWithFormat("Unable to parse the specified JSON file")
            case .deleteWebhookFailed(let webhookID, let error):
                return String.localizedStringWithFormat("Unable to delete the webhook %1@ with error %2@", "\(webhookID)", "\(error)")
            }
        }
    }
    
    
#endif
