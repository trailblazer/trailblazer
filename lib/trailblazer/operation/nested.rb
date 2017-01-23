class Trailblazer::Operation
  def self.Nested(step, input:nil)
    step = Nested.for(step, input)

    [ step, { name: "Nested(#{step})" } ]
  end

  module Nested
    # The returned lambda will be executed at runtime and call the nested operation.
    def self.invoker_for(step)
      if step.is_a?(Class) && step <= Trailblazer::Operation # interestingly, with < we get a weird nil exception. bug in Ruby?
        invoker = Caller.new(step)
      else
        invoker = Caller::Dynamic.new(step)
      end
    end

    class Caller
      def initialize(step)
        @step = step
      end

      def call(input, options, options_for_nested)
        call_nested(nested(input, options), options_for_nested)
      end

    private
      def nested(input, options)
        @step
      end

      def call_nested(operation, options)
        operation._call(options)
      end

      class Dynamic < Caller
        def initialize(step)
          @step = Option::KW.(step)
        end

        def nested(input, options)
          @step.(input, options)
        end
      end
    end

    class Options
      # Per default, only runtime data for nested operation.
      def call(input, options)
        options.to_runtime_data[0]
      end

      class Dynamic
        def initialize(mapper)
          @mapper = Option::KW.(mapper)
        end

        def call(operation, options)
          @mapper.(operation, options, runtime_data: options.to_runtime_data[0], mutable_data: options.to_mutable_data )
        end
      end
    end

    # Please note that the instance_variable_get are here on purpose since the
    # superinternal API is not entirely decided, yet.
    def self.for(step, input)
      invoker = invoker_for(step)

      options_for_nested = Options.new
      options_for_nested = Options::Dynamic.new(input) if input

      # This lambda is the strut added on the track, executed at runtime.
      ->(operation, options) do
        result = invoker.(operation, options, options_for_nested.(operation, options)) # TODO: what about containers?

        result.instance_variable_get(:@data).to_mutable_data.each { |k,v| options[k] = v }
        result.success? # DISCUSS: what if we could simply return the result object here?
      end
    end
  end
end

