# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'raise-if-root/version'

Gem::Specification.new do |spec|
  spec.name          = 'raise-if-root'
  spec.version       = RaiseIfRoot::VERSION
  spec.authors       = ['Andy Brody']
  spec.email         = ['git@abrody.com']
  spec.summary       = 'Library that raises when run as root user'
  spec.description   = <<-EOM
    Raise If Root is a small library that raises an exception when run as the
    root user (uid 0). This helps ensure that you never accidentally run your
    application as root.
  EOM
  spec.homepage      = 'https://github.com/ab/raise-if-root'
  spec.license       = 'GPL-3'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.49'
  spec.add_development_dependency 'yard'

  spec.required_ruby_version = '>= 2.0'
end
