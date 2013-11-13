# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zulip_machine/version'

Gem::Specification.new do |spec|
  spec.name          = "zulip_machine"
  spec.version       = ZulipMachine::VERSION
  spec.authors       = ["Alan O'Donnell"]
  spec.email         = ["alan.m.odonnell@gmail.com"]
  spec.description   = "EventMachine bindings for Zulip's API."
  spec.summary       = "EventMachine bindings for Zulip's API."
  spec.homepage      = "https://github.com/happy4crazy/zulip_machine"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "em-http-request", "~> 1.1.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
