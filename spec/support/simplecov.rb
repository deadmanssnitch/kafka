# frozen_string_literal: true

begin
  require "simplecov"

  # Enable code coverage analysis
  SimpleCov.start do
    enable_coverage :branch

    # Ignore spec files since they should be fully covered
    add_filter "/spec/"
  end
rescue LoadError
  # SimpleCov is defined in the Gemfile but not in the gemspec and is optional
  # for development.
end
