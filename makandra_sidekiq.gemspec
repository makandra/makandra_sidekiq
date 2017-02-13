# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'makandra_sidekiq/version'

Gem::Specification.new do |spec|
  spec.name          = "makandra_sidekiq"
  spec.version       = MakandraSidekiq::VERSION
  spec.authors       = ["Tobias Kraze"]
  spec.email         = ["tobias.kraze@makandra.de"]

  spec.summary       = %q{Support code for sidekiq, including rake tasks and capistrano recipes.}
  spec.homepage      = "https://github.com/makandra/makandra_sidekiq"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
