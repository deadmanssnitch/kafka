# frozen_string_literal: true

require_relative "lib/kafka/version"

Gem::Specification.new do |spec|
  spec.name          = "kafka"
  spec.version       = Kafka::VERSION
  spec.authors       = ["Chris Gaffney"]
  spec.email         = ["gaffneyc@gmail.com"]

  spec.summary       = "Kafka client bindings to librdkafka"
  spec.description   = <<~DESCRIPTION
    Kafka provides binding to librdafka as well as a default producer and
    consumer implementation.
  DESCRIPTION

  spec.homepage      = "https://deadmanssnitch.com/opensource/kafka"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "bug_tracker_uri" => "https://github.com/deadmanssnitch/kafka/issues",
    "source_code_uri" => "https://github.com/deadmanssnitch/kafka",
    "documentation_uri" => "https://deadmanssnitch.com/opensource/kafka/docs/",
    "changelog_uri" => "https://github.com/deadmanssnitch/kafka/blob/master/CHANGELOG.md",
    "rubygems_mfa_required" => "true",
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.require_paths = ["lib"]
  spec.extensions    = %w[ext/Rakefile]

  spec.add_dependency "ffi"
  spec.add_dependency "mini_portile2"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-eventually"
end
