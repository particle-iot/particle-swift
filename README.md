# particle-swift

Swift 3.0 Package for interacting with Particle Cloud services 

*Compatibility:* Xcode 8 (Swift 3.0) or the equivalent open source variant of Swift is required.

This project provides a pure Swift SDK for interacting with the particle.io cloud services.  The 
APIs provide access to the following portions of the Particle Cloud

  * Authentication
  * Devices
  * Webhooks
  * Events

This project has the following long term goals

  * Follow pure swift design and coding styles
  * Be dependency free
  * Work with the swift package manager and provide frameworks for iOS, macOS, tvOS, and watchOS

Some general design guidelines are 

  * Delegate secured storage of credentials to the caller.  Higher level consumers can store in keychain, etc.
  * Generally be a stateless (outside of authentication) API set for the Particle Cloud services. 
  * Be compatible with Linux and other swift ports (long term goal)
  * Multi-user concurrency.  Multiple particle cloud accounts may be created and used at the same time.

Intended usages for this library would include server side Swift, iOS/tvOS/macOS/watchOS applications that utilize particle cloud service, or any other Swift based product that wants to use the awesome Particle Cloud.

A swift package manager compatible executable project is available [here](https://github.com/vakoc/particle-swift-cli). 

Using the Library
-------

particle-swift can be used by by any platform that is supported by the Swift Package Manager (SPM) or directly by Xcode for Apple based platforms.

SPM based deployments simply need to include the particle-swift github url in the Package.swift as shown below.  The particle-swift-cli, for example, utilizes particle-swift by delcaring it in Package.swift as follows

```swift
import PackageDescription

let package = Package(
    name: "particle-swift-cli",
    dependencies: [
        .Package(url: "https://github.com/vakoc/particle-swift.git", versions: Version(0,0,0)...Version(1,0,0)),
    ]
)
```

The SPM supports only macOS targets on the Apple platforms and command line applications on Linux.  Traditional iOS, tvOS, watchOS, or macOS applications may also utilize particle-swift by simply cloning the git repository and adding the source managed Xcode/ParticleSwift.xcodeproj Xcode project directly into their sources.  

This Xcode project provides Swift frameworks for each of those platforms.  Simply add the corresponding framework as an embedded framework to your application.  Any source files that want to utilize particle-swift should import the module as shown below

```swift
import Foundation
import ParticleSwift

let particleCloud = ParticleCloud(.....)
```

Getting Started
-------
particle-swift provides the APIs to interact with the Particle Cloud webservices.  Authentication is handled by the library but credential storage is not; the caller is reponsible for providing and securely storing sensitive information.  Apple platorms provide keychain storage which is suitable for persisting sensitive information.  

The following sample provides an example of using particle-swift with basic and  insecure credential management.  Keychain services is beyond the scope of this example.  Note:  ParticleCloud instances are not singletons and is fully supported to have multiple instances run concurrently that may utilize separate OAuth realms at the same time.  Multi-user concurrency is an essential design goal of this library.

```swift
import Foundation
import ParticleSwift

// Illustrative example utilizing insecure UserDefaults for token storage and hard coded
// user names.  Production apps should use more secure mechanisms like the Keychain services 
// provided by the OS
class MyParticleCloud {
    
    var token: OAuthToken?
    var particleCloud: ParticleCloud?
    
    init() {
        if let dictionary = UserDefaults.standard.value(forKey: "token") as? Dictionary<String,Any> {
            self.token = OAuthToken(with: dictionary)
        }
        particleCloud = ParticleCloud(secureStorage: self)
    }
    
    func callFunctionOnAllMyDevices() {
        
        particleCloud?.devices { result in
            switch (result) {
            case .success(let devices):
                devices.forEach { device in
                    self.particleCloud?.callFunction("myFunction", deviceID: device.deviceID, argument: "7") { functionResult in
                        
                        switch (functionResult) {
                            case .success(let retVal):
                                print("Result of myFunction(7) device \(device.name) was \(retVal)")
                            case .failure(let error):
                                print("Error:  Failed to call myFunction(7) on device \(device.name) with error \(error)")
                        }
                    }
                }
            case .failure(let error):
                print("Error:  Unable to enumerate all devices with function \(error)")
            }
        }
    }
}

extension MyParticleCloud: SecureStorage {
    
    func username(_ realm: String) -> String? {
        return "myuser"
    }
    
    func password(_ realm: String) -> String? {
        return "mypassword"
    }
    
    func oauthClientId(_ realm: String) -> String? {
        return "particle"
    }
    
    func oauthClientSecret(_ realm: String) -> String? {
        return "particle"
    }
    
    func oauthToken(_ realm: String) -> OAuthToken? {
        return token
    }
    
    func updateOAuthToken(_ token: OAuthToken?, forRealm realm: String) {
        self.token = token
        /// Persist this for subsequent runs
        UserDefaults.standard.set(token.dictionary, forKey: "token")
    }
}
```

The following example uses the MyParticleCloud class to call a function on all devices assocaited with the user's account.

```swift
let cloud = MyParticleCloud()
cloud.callFunctionOnAllMyDevices()
```

Note:  if you are using particle-swift in a command line style application you will need to create a runloop.  All particle-swift interactions are asynchronous and utliize background threads for network communications.  Create a runloop like

```swift
RunLoop.current.run(until: Date.distantFuture)
```

Refer to the particle-swift-cli sample application, which utilizes every particle-swift capability, for more examples on how to make use of this framework.

Versioning
-------
Swift package manager based projects utilize only tagged releases that match the versions specified in the Package.swift manifest file.  As such releases of this library are created often.  Version numbers follow the semantic versioning system of MAJOR.MINOR.PATCH.  While every attempt is made to prevent source level incompatibilities between patch level versions, at this point, this is not guaranteed.  

Linux Support
-------
particle-swift (and particle-swift-cli) currently compile and function on Linux.  Known bugs exist in 3.0.1 and 3.0.2 verions of swift on Linux that can prevent HTTP headers from being properly included in requests, which is extremely significant to this library.  As such a recent Swift snapshots (later than ~ Oct 20, 2016) resolve this issue.

Linux support is an important long term goal of this project and every effort is made to make it work as well on Linux as on Apple platforms.  Swift on Linux is rather unstable IMHO and the focus of Linux support will be concerned only with using recent Swift builds.

The most recent Swift build known to work is swift-DEVELOPMENT-SNAPSHOT-2016-11-15-a-ubuntu16.04.

Roadmap
-------

APIs should be relatively stable but are subject to change.  Additional Particle Cloud functionality is being added
in the following general order

  * Firmware

Once complete additional functionality will be added.

License
-------
All code is licenced under the Apache 2.0 license.  See http://www.vakoc.com/LICENSE.txt for more information.
