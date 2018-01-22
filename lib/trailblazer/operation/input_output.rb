module Trailblazer
  # Add an input and output filter for a task, allowing to control what a task "sees"
  # (receives as input) and returns (or, what the outer caller "sees").
  #
  # This works by adding two variable mappers to the taskWrap.
  # One before the actual task gets called (input) and one before the end (output).
  module Operation::InputOutput
  # naming: Macaroni, VariableMapping
    def self.plan(input, output)
      default_input_filter  = ->(options, *) { ctx = options }
      default_output_filter = ->(options, *) { options }

      input  ||= default_input_filter
      output ||= default_output_filter

      input_filter  = Activity::TaskWrap::Input.new(input)
      output_filter = Activity::TaskWrap::Output.new(output)

      # taskWrap extensions
      Module.new do
        extend Activity::Path::Plan()

        task input_filter,  id: ".input",  before: "task_wrap.call_task"
        task output_filter, id: ".output", before: "End.success", group: :end # DISCUSS: position
      end
    end
  end
end
