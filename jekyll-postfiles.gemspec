# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll-postfiles/version'

Gem::Specification.new do |spec|
  spec.name          = "jekyll-postfiles"
  spec.version       = JekyllPostFiles::VERSION
  spec.authors       = ["Nicolas Hoizey"]
  spec.email         = ["nicolas@hoizey.com"]

  spec.summary       = %q{A Jekyll plugin to keep posts assets alongside their Markdown files}
  spec.description   = %q{This plugin takes any file that is in posts folders, and copy them to the folder in which the post HTML page will be created.}
  spec.homepage      = "https://nhoizey.github.io/jekyll-postfiles/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rubocop", "~> 0.42"
end
