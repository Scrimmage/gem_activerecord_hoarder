# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "activerecord_hoarder/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord_hoarder"
  spec.version = ActiverecordHoarder::VERSION
  spec.authors = ["Matthias Engh"]
  spec.email = ["matthias@wescrimmage.com"]

  spec.summary = %q{hoards records}
  spec.description = %q{extend active records with simple archiving mechanics}
  spec.homepage = "https://github.com/Scrimmage/gem_batch_archiving"
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", [">= 4.2", "< 6.0"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
