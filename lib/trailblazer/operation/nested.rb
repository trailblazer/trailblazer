class Trailblazer::Operation
  def self.Nested(step, input:nil)
    step = Nested.for(step, input)

    [ step, {} ]
  end

  module Nested
    # _call the nested `operation`.
    Call = ->(operation, options) { operation._call(options) }

    def self.caller_for(step, input)
      if step.is_a?(Class) && step <= Trailblazer::Operation # interestingly, with < we get a weird nil exception. bug in Ruby?
        caller = ->(input, options, options_for_nested) { Call.(step, options_for_nested) }
      else
        option = Option::KW.(step)
        caller = ->(input, options, options_for_nested) {
          operation_class = option.(input, options)
          Call.(operation_class, options_for_nested) }
      end
    end

    # Please note that the instance_variable_get are here on purpose since the
    # superinternal API is not entirely decided, yet.
    def self.for(step, input)
      invoker = caller_for(step, input)

      options_for_nested = ->(operation, options) { options.to_runtime_data[0] } # per default, only runtime data for nested operation.
      options_for_nested = ->(operation, options) { Option::KW.(input).(operation, options, runtime_data: options.to_runtime_data[0], mutable_data: options.to_mutable_data ) } if input

      # The lambda is the strut added on the track, executed at runtime.
      ->(operation, options) do
        result = invoker.(operation, options, options_for_nested.(operation, options)) # TODO: what about containers?

        result.instance_variable_get(:@data).to_mutable_data.each { |k,v| options[k] = v }
        result.success? # DISCUSS: what if we could simply return the result object here?
      end
    end
  end
end

