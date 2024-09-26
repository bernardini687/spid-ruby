# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "spid/version"

Gem::Specification.new do |spec|
  spec.name       = "spid"
  spec.version    = Spid::VERSION
  spec.authors    = ["David Librera"]
  spec.email      = ["davidlibrera@gmail.com"]
  spec.homepage   = "https://github.com/italia/spid-ruby"
  spec.summary    = "SPID (https://www.spid.gov.it) integration for ruby"
  spec.license    = "BSD-3"
  spec.files      = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.metadata    = {
    "homepage_uri" => "https://github.com/italia/spid-ruby",
    "changelog_uri" => "https://github.com/italia/spid-ruby/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/italia/spid-ruby/",
    "bug_tracker_uri" => "https://github.com/italia/spid-ruby/issues",
    "rubygems_mfa_required" => "true"
  }
  spec.required_ruby_version = ">= 3.3.5"

  spec.add_dependency "activesupport", ">= 3.0.0", "< 8.0"
  spec.add_dependency "listen", ">= 0"
  spec.add_dependency "rack", ">= 1", "< 4"
  spec.add_dependency "rake", ">= 10.0", "< 14"
  spec.add_dependency "rexml", "~> 3.3", ">= 3.3.7"
  spec.add_dependency "xmldsig", ">= 0.6.6"

  # Development dependencies have been removed in favor of specifying them in the Gemfile.
end
