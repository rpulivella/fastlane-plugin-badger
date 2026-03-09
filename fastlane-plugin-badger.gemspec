lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fastlane/plugin/badger/version"

Gem::Specification.new do |spec|
  spec.name          = "fastlane-plugin-badger"
  spec.version       = Fastlane::Badger::VERSION
  spec.author        = "rpulivella"
  spec.email         = ""

  spec.summary       = "Generates app icon badges locally using ImageMagick — " \
                       "no shields.io, no network, no static PNGs"
  spec.description   = <<~DESC
    Badger composites version/build text badges and diagonal corner ribbon banners
    directly onto your app icons at build time using ImageMagick (via mini_magick).
    No shields.io, no network calls, no pre-rendered PNGs committed to the repo.
    Works entirely offline and runs identically on developer machines and CI.

    Bundled fonts (both SIL Open Font License):
      - JetBrains Mono NL Bold  — for version/build/ticket text badges
      - Figtree Black            — for corner ribbon banners
  DESC
  spec.homepage      = "https://github.com/rpulivella/fastlane-plugin-badger"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.6"

  spec.files = Dir[
    "lib/**/*.rb",
    "assets/**/*",
    "LICENSE",
    "README.md"
  ].reject { |f| File.directory?(f) }

  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "mini_magick", "~> 4.0"

  # Development dependencies
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "fastlane"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "simplecov"
end
