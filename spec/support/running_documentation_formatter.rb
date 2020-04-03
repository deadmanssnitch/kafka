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
    output.write "#{current_indentation}#{notification.example.description.strip}"
  end

  private 

  def passed_output(example)
    reset_line
    super
  end

  def pending_output(example, message)
    reset_line
    super
  end

  def failure_output(example)
    reset_line
    super
  end

  # clears the current line so the correctly formatted success, failure, or
  # pending is correctly colored.
  def reset_line
    output.write "\33[2K\r"
  end
end
