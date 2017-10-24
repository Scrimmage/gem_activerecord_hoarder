# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "batch_archiving/version"

Gem::Specification.new do |spec|
  spec.name = "batch_archiving"
  spec.version = BatchArchiving::VERSION
  spec.authors = ["mchadwick MatthiasEngh"]
  spec.email = ["matthias@wescrimmage.com"]

  spec.summary = %q{archive records in batches}
  spec.description = %q{extend active records with simple archiving mechanics}
  spec.homepage = "https://github.com/Scrimmage/gem_batch_archiving"
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["lib/**/*", "README.md"]

  spec.require_path = "lib"

  spec.add_dependency "activerecord", [">= 4.2", "< 6.0"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
