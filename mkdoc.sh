#/bin/bash
swift package generate-xcodeproj
jazzy --clean --author "Mark Vakoc" --github_url "https://github.com/vakoc/particle-swift" --output Docs 
rm -r ParticleSwift.xcodeproj
open Docs/index.html
