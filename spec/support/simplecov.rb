# frozen_string_literal: true

begin
  require "simplecov"

  # Enable code coverage analysis
  SimpleCov.start do
    enable_coverage :branch

    # Ignore spec files since they should be fully covered
    add_filter "/spec/"

    ffi = %r{lib/kafka/ffi/}
    add_group("client") { |f| !ffi.match?(f.filename) }
    add_group("ffi")    { |f|  ffi.match?(f.filename) }
  end
rescue LoadError
  # SimpleCov is defined in the Gemfile but not in the gemspec and is optional
  # for development.
end
