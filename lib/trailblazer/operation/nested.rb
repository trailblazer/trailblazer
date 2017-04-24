class Trailblazer::Operation
  def self.Nested(callable, input:nil, output:nil)
    step = Nested.for(callable, input, output)

    [ step, { name: "Nested(#{callable})" } ]
  end

  # WARNING: this is experimental API, but it will end up with something like that.
  module Element
    # DISCUSS: add builders here.
    def initialize(wrapped=nil)
      @wrapped = wrapped
    end

    module Dynamic
      def initialize(wrapped)
        @wrapped = Option::KW.(wrapped)
      end
    end
  end

  module Nested
    # Please note that the instance_variable_get are here on purpose since the
    # superinternal API is not entirely decided, yet.
    # @api private
    def self.for(step, input, output, is_nestable_object=method(:nestable_object?)) # DISCUSS: use builders here?
      invoker            = Caller::Dynamic.new(step)
      invoker            = Caller.new(step) if is_nestable_object.(step)

      options_for_nested = Options.new
      options_for_nested = Options::Dynamic.new(input) if input

      options_for_composer = Options::Output.new
      options_for_composer = Options::Output::Dynamic.new(output) if output

      # This lambda is the strut added on the track, executed at runtime.
      ->(operation, options) do
        result = invoker.(operation, options, options_for_nested.(operation, options)) # TODO: what about containers?

        options_for_composer.(operation, options, result).each { |k,v| options[k] = v }

        result.success? # DISCUSS: what if we could simply return the result object here?
      end
    end

    def self.nestable_object?(object)
      # interestingly, with < we get a weird nil exception. bug in Ruby?
      object.is_a?(Class) && object <= Trailblazer::Operation
    end

    # Is executed at runtime and calls the nested operation.
    class Caller
      include Element

      def call(input, options, options_for_nested)
        call_nested(nested(input, options), options_for_nested)
      end

    private
      def call_nested(operation, options)
        operation._call(options)
      end

      def nested(*); @wrapped end

      class Dynamic < Caller
        include Element::Dynamic

        def nested(input, options)
          @wrapped.(input, options)
        end
      end
    end

    class Options
      include Element

      # Per default, only runtime data for nested operation.
      def call(input, options)
        options.to_runtime_data[0]
      end

      class Dynamic
        include Element::Dynamic

        def call(operation, options)
          @wrapped.(operation, options, runtime_data: options.to_runtime_data[0], mutable_data: options.to_mutable_data )
        end
      end

      class Output
        include Element

        def call(input, options, result)
          mutable_data_for(result).each { |k,v| options[k] = v }
        end

        def mutable_data_for(result)
          result.instance_variable_get(:@data).to_mutable_data
        end

        class Dynamic < Output
          include Element::Dynamic

          def call(input, options, result)
            @wrapped.(input, options, mutable_data: mutable_data_for(result))
          end
        end
      end
    end
  end
end

