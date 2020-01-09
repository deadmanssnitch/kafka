# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Build librdkafka into ext"
task :ext do
  if Dir.glob("ext/librdkafka.*").empty?
    sh "cd ext && rake"
  end
end

task default: [:ext, :spec]

namespace :ffi do
  desc "Lists the librdkafka functions that have not been implemented in Kafka::FFI"
  task :missing do
    require_relative "lib/kafka/version"

    require "uri"
    require "net/http"
    require "tempfile"

    header = Tempfile.new(["rdkafka", ".h"])

    # Fetch the header for the pinned version of librdkafka. rdkafka.h contains
    # all of the exported function prototypes.
    url = URI("https://raw.githubusercontent.com/edenhill/librdkafka/v#{::Kafka::LIBRDKAFKA_VERSION}/src/rdkafka.h")
    resp = Net::HTTP.get(url)
    header.write(resp)
    header.close

    all = `ctags -x --sort=yes --kinds-C=pf #{header.path} | awk '{ print $1 }'`
    all = all.split("\n")

    ffi_path = File.expand_path("lib/kafka/ffi.rb", __dir__)
    implemented = `grep -o -h -P '^\\s+attach_function\\s+:\\Krd_kafka_\\w+' #{ffi_path}`
    implemented = implemented.split("\n").sort

    missing = all - implemented
    puts missing
  ensure
    header.unlink
  end

  desc "Prints the list of implemented librdkafka functions"
  task :implemented do
    ffi_path = File.expand_path("lib/kafka/ffi.rb", __dir__)
    puts `grep -o -h -P '^\\s+attach_function\\s+:\\Krd_kafka_\\w+' #{ffi_path} | sort`
  end
end
