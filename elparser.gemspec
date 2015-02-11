# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elparser/version'

Gem::Specification.new do |spec|
  spec.name          = "elparser"
  spec.version       = Elparser::VERSION
  spec.authors       = ["SAKURAI Masashi"]
  spec.email         = ["m.sakurai@kiwanami.net"]
  spec.summary       = %q{A parser for S-expression of emacs lisp}
  spec.description   = %q{A parser for S-expression of emacs lisp}
  spec.homepage      = "https://github.com/kiwanami/ruby-elparser"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = ['readme.html']

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "racc", "~> 1.4"
  spec.add_development_dependency "test-unit", "~> 3.0"
end
