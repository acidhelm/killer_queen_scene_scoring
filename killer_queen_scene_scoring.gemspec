lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "date"
require "killer_queen_scene_scoring/version"

Gem::Specification.new do |spec|
    spec.name = "killer_queen_scene_scoring"
    spec.version = KillerQueenSceneScoring::VERSION
    spec.authors = ["Michael Dunn"]
    spec.email = ["acidhelm@gmail.com"]
    spec.date = Date.today.strftime("%F")

    spec.summary = "Scene-wide scoring for Killer Queen tournaments."
    spec.description = "Classes that implement scene-wide scoring for Killer Queen tournaments."
    spec.homepage = "https://githumb.com/acidhelm/killer_queen_scene_scoring"
    spec.license = "MIT"

    # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
    # to allow pushing to a single host or delete this section to allow pushing to any host.
    if spec.respond_to?(:metadata)
        spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

        spec.metadata["homepage_uri"] = spec.homepage
        spec.metadata["source_code_uri"] = spec.homepage
        # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
    else
        raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
    end

    # Specify which files should be added to the gem when it is released.
    # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
    spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
        `git ls-files -z`.split("\x0").reject { |f| f.match(/^(test|spec|features)\//) }
    end

    spec.bindir = "exe"
    spec.executables = spec.files.grep(/^exe\//) { |f| File.basename(f) }
    spec.require_paths = ["lib"]

    spec.add_development_dependency "bundler", "~> 1.17"
    spec.add_development_dependency "minitest", "~> 5.0"
    spec.add_development_dependency "rake", "~> 10.0"

    spec.add_runtime_dependency "dotenv"
    spec.add_runtime_dependency "json"
    spec.add_runtime_dependency "rest-client"
end
