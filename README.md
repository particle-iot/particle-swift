# particle-swift
Swift 3.0 Package for interacting with Particle Cloud services 

This is a very early stage of porting a non-public (but entirely written by me) Swift based particle
framework.  The particle relaated bits will be separated from more derivative type functionality which 
may or may not become open source.

This project has the following long term goals

  * Follow pure swift design and coding styles
  * Be dependency free (other than other projects authored by myself, and those will be minimal)
  * Work with the swift package manager and provide frameworks for iOS, macOS, tvOS, and watchOS

Some general design guidelines are 

  * Delegate secured storage of credentials to the caller.  Higher level consumers can store in keychain, etc.
  * Generally be a stateless (outside of authentication) API set for the Particle Cloud services. 
  * Be compatible with Linux and other swift ports (long term goal)

Intended usages for this library would include server side Swift, iOS/tvOS/macOS/watchOS applications that utilize particle cloud service, or any other Swift based product that wants to use the awesome Particle Cloud.

Roadmap
-------

Although derived/ported from a fairly mature codebase, I consider this a rewrite to adopt Swift 3.0 patterns
and decouple the core Particle functionality from a more more complex framework.

Work will focus on porting a small portion to adopt Swift 3.0 then migrate the remaining (bulk of) functionality.

This should be considered earlier than alpha functionality and anything can change in the next commit.

License
-------
All code is licenced under the Apache 2.0 license.  See http://www.vakoc.com/LICENSE.txt for more information.
