import PackageDescription

let package = Package(
    name: "ParticleSwift",
	dependencies: [
        .Package(url: "https://github.com/vakoc/logging.git", versions: Version(0,0,0)...Version(1,0,0)),
    ]
)
