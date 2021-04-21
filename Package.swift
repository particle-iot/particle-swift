// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ParticleSwift",
    products: [
        .library(name: "ParticleSwift", targets: ["ParticleSwift"])
    ],
	dependencies: [],
    targets: [
        .target(name: "ParticleSwift", path: "Sources")
    ]
)
