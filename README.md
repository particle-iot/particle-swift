# particle-swift

Swift 3.0 Package for interacting with Particle Cloud services 

*Compatibility:* Swift 3.0 (Xcode 8) or the equivalent open source variant of Swift is required.

This project provides a pure Swift SDK for interacting with the particle.io cloud services.  The 
APIs provide access to the following portions of the Particle Cloud

  * Authentication
  * Devices

This project has the following long term goals

  * Follow pure swift design and coding styles
  * Be dependency free (other than other projects authored by myself, and those will be minimal)
  * Work with the swift package manager and provide frameworks for iOS, macOS, tvOS, and watchOS

Some general design guidelines are 

  * Delegate secured storage of credentials to the caller.  Higher level consumers can store in keychain, etc.
  * Generally be a stateless (outside of authentication) API set for the Particle Cloud services. 
  * Be compatible with Linux and other swift ports (long term goal)

Intended usages for this library would include server side Swift, iOS/tvOS/macOS/watchOS applications that utilize particle cloud service, or any other Swift based product that wants to use the awesome Particle Cloud.

A swift package manager compatible executable project is available [here](https://github.com/vakoc/particle-swift-cli).  


Roadmap
-------

APIs should be relatively stable but are subject to change.  Additional Particle Cloud functionality is being added
in the following general order

  * Webhooks
  * Events
  * Firmware

Once complete additional functionality will be added.

License
-------
All code is licenced under the Apache 2.0 license.  See http://www.vakoc.com/LICENSE.txt for more information.
