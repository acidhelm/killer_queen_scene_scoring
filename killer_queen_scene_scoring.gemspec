lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "date"
require "killer_queen_scene_scoring/version"

Gem::Specification.new do |spec|
    spec.name = "killer_queen_scene_scoring"
    spec.version = KillerQueenSceneScoring::VERSION
    spec.authors = ["Michael Dunn"]
    spec.email = ["acidhelm@gmail.com"]
    spec.required_ruby_version = "~> 2.6.0"

    spec.summary = "Scene-wide scoring for Killer Queen tournaments."
    spec.description = "Classes that implement scene-wide scoring for Killer Queen tournaments."
    spec.homepage = "https://github.com/acidhelm/killer_queen_scene_scoring"
    spec.license = "MIT"

    if spec.respond_to?(:metadata)
        spec.metadata["allowed_push_host"] = "https://rubygems.org"
        spec.metadata["homepage_uri"] = spec.homepage
        spec.metadata["source_code_uri"] = spec.homepage
        # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
    else
        raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
    end

    # Specify which files should be added to the gem when it is released.
    spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
        `git ls-files -z`.split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }
    end

    spec.bindir = "exe"
    spec.executables = spec.files.grep(/^exe\//) { |f| File.basename(f) }
    spec.require_paths = ["lib"]

    spec.add_development_dependency "bundler", "~> 1.17"
    spec.add_development_dependency "minitest", "~> 5.0"
    spec.add_development_dependency "rake", "~> 10.0"
    spec.add_development_dependency "vcr", "~> 4.0"
    spec.add_development_dependency "webmock", "~> 3.5.1"

    spec.add_runtime_dependency "dotenv", "~> 2.7"
    spec.add_runtime_dependency "json", "~> 2.2"
    spec.add_runtime_dependency "rest-client", "~> 2.0"
end
