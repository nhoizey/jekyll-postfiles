# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))
require "jekyll/postfiles/version"

Gem::Specification.new do |spec|
  spec.version = Jekyll::PostFiles::VERSION
  spec.homepage = "https://nhoizey.github.io/jekyll-postfiles/"
  spec.authors = ["Nicolas Hoizey"]
  spec.email = ["nicolas@hoizey.com"]
  spec.files = %w(Rakefile Gemfile README.md RELEASES.md LICENSE) + Dir["lib/**/*"]
  spec.summary = "A Jekyll plugin to keep posts assets alongside their Markdown files"
  spec.name = "jekyll-postfiles"
  spec.license = "MIT"
  spec.require_paths = ["lib"]
  spec.description   = <<-DESC
    This plugin takes any file that is in posts folders, and copy them to the folder in which the post HTML page will be created.
  DESC

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_runtime_dependency "jekyll", ">= 3.6", "< 5"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 0.76.0"
end
