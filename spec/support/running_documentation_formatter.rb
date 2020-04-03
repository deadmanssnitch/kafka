require "rspec/core/formatters/documentation_formatter"

# RunningDocumentationFormatter is an rspec formatter designed to print the
# name of the running tests before any output from the test is written. The
# default DocumentationFormatter only prints the test's name after it has
# finished which is not useful should we get a segfault.
class RunningDocumentationFormatter < RSpec::Core::Formatters::DocumentationFormatter
  RSpec::Core::Formatters.register self,
    :example_started, :example_group_started, :example_group_finished,
    :example_passed, :example_pending, :example_failed

  def example_started(notification)
    super
    output.puts "#{current_indentation}#{notification.example.description.strip}"
  end

  private 

  def passed_output(example)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}  success", :success)
  end

  def pending_output(example, message)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}  (PENDING: #{message})", :pending)
  end

  def failure_output(example)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}  (FAILED - #{next_failure_index})", :failure)
  end
end
