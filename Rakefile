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
  require "uri"
  require "net/http"
  require "tempfile"

  def header
    header = Tempfile.new(["rdkafka", ".h"])

    # Extract the LIBRDKAFKA_VERSION constant from the Rakefile to know which
    # version to fetch. This used to be in version.rb was it was moved out of
    # the public API. This is not the cleanest but it allows extracting it
    # without having to load the full library.
    version = /^LIBRDKAFKA_VERSION\s+=\s+"(\d+\.\d+\.\d+)"/.match(File.read("ext/Rakefile"))[1]

    # Fetch the header for the pinned version of librdkafka. rdkafka.h contains
    # all of the exported function prototypes.
    url = URI("https://raw.githubusercontent.com/edenhill/librdkafka/v#{version}/src/rdkafka.h")
    resp = Net::HTTP.get(url)
    header.write(resp)
    header.close

    at_exit { header.unlink }

    header.path
  end

  desc "Lists the librdkafka functions that have not been implemented in Kafka::FFI"
  task :missing do
    all = `ctags -x --sort=yes --kinds-C=pf #{header} | awk '{ print $1 }'`
    all = all.split("\n")

    ffi_path = File.expand_path("lib/kafka/ffi.rb", __dir__)
    implemented = `grep -o -h -P '^\\s+attach_function\\s+:\\Krd_kafka_\\w+' #{ffi_path}`
    implemented = implemented.split("\n").sort

    missing = all - implemented
    puts missing
  end

  desc "Prints the list of implemented librdkafka functions"
  task :implemented do
    ffi_path = File.expand_path("lib/kafka/ffi.rb", __dir__)
    puts `grep -o -h -P '^\\s+attach_function\\s+:\\Krd_kafka_\\w+' #{ffi_path} | sort`
  end

  namespace :sync do
    desc "Update ffi.rb with all errors defined in rdkafka.h"
    task :errors do
      ffi_path = File.expand_path("lib/kafka/ffi.rb", __dir__)

      cmd = [
        # Find all of the enumerator types in the header
        "ctags -x --sort=no --kinds-C=e #{header}",

        # Reduce it to just RD_KAFKA_RESP_ERR_* and their values
        "grep -o -P 'RD_KAFKA_RESP_ERR_\\w+ = -?\\d+'",

        # Add spacing to the constants so they line up correctly.
        "sed -e 's/^/    /'",

        # Delete any existing error constants then append the generated result.
        "sed -e '/^\\s\\+RD_KAFKA_RESP_ERR_.\\+=.\\+/d' -e '/Response Errors/r /dev/stdin' #{ffi_path}",
      ].join(" | ")

      File.write(ffi_path, `#{cmd}`, mode: "w")
    end
  end
end

namespace :kafka do
  desc "Start an instance of Kafka running in docker"
  task :up, [:version] do |_, args|
    compose =
      if args[:version]
        "spec/support/kafka-#{args[:version]}.yml"
      else
        # Find the docker-compose file for the most recent version of Kafka in
        # spec/support.
        Dir["spec/support/kafka-*.yml"].max
      end

    sh "docker-compose -p ruby_kafka_dev -f #{compose} up -d"
  end

  desc "Shutdown the development Kafka instance"
  task :down do
    sh "docker-compose -p ruby_kafka_dev down"
  end

  desc "Tail logs from the running Kafka instance"
  task :logs do
    exec "docker-compose -p ruby_kafka_dev logs -f"
  end
end
