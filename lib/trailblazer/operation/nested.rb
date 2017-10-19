# per default, everything we pass into a circuit is immutable. it's the ops/act's job to allow writing (via a Context)
module Trailblazer
  class Operation
    def self.Nested(callable, input:nil, output:nil, name: "Nested(#{callable})")
      task_wrap_wirings = []

      task, operation = Nested.build(callable, input, output)

      # @needs operation#outputs

      default_input_filter  = ->(options, *) { ctx = options }
      default_output_filter = ->(options, *) {

        # p options
       options.decompose.last
       options
       } # DISCUSS: per default, grab them

      # TODO: move this to the generic step DSL
      if input || output

        input  ||= default_input_filter
        output ||= default_output_filter

        input_task = Activity::Input.new(input, nil)
        task_wrap_wirings << [ :insert_before!, "task_wrap.call_task", node: [ input_task, id: ".input" ], incoming: Proc.new{true}, outgoing: [Trailblazer::Circuit::Right, {}] ]

        output_task = Activity::Output.new( output, Activity::Output::CopyMutableToOriginal )
        task_wrap_wirings << [ :insert_before!, "End.default", node: [ output_task, id: ".output" ], incoming: Proc.new{true}, outgoing: [Trailblazer::Circuit::Right, {}] ]
      end
        # Default {Output} copies the mutable data from the nested activity into the original.

      { task: task, node_data: { id: name }, runner_options: { alteration: task_wrap_wirings }, outputs: operation.outputs }
    end

    # @private
    module Nested
      module Nestable
      end

      def self.build(nested_operation, input, output, is_nestable_object=method(:nestable_object?)) # DISCUSS: use builders here?
        nested_activity = is_nestable_object.(nested_operation) ? nested_operation : Dynamic.new(nested_operation)

        # The returned {Nested} instance is a valid circuit element and will be `call`ed in the circuit.
        # It simply returns the nested activity's `signal,options,flow_options` return set.
        # The actual wiring - where to go with that - is done by the step DSL.
        return Trailblazer::Activity::Subprocess(nested_activity, call: :__call__), nested_activity
      end

      def self.nestable_object?(object)
        # interestingly, with < we get a weird nil exception. bug in Ruby?
        object.is_a?(Nestable) || object.is_a?(Class) && object <= operation_class
      end

      def self.operation_class
        Trailblazer::Operation
      end

      private

      # For dynamic `Nested`s that do not expose an {Activity} interface.
      # Since we do not know its outputs, we have to map them to :success and :failure, only.
      #
      # This is what {Nested} in 2.0 used to do, where the outcome could only be true/false (or success/failure).
      class Dynamic
        def initialize(wrapped)
          @wrapped = Trailblazer::Option::KW(wrapped)
          @outputs = {
            Railway::End::Success.new(:success) => { role: :success },
            Railway::End::Failure.new(:failure) => { role: :failure },
          }
        end

        attr_reader :outputs

        def __call__( (options, flow_options), **circuit_options )
          activity = @wrapped.(options, circuit_options) # evaluate the option to get the actual "object" to call.

          signal, args = activity.__call__( [options, flow_options], **circuit_options )

          # Translate the genuine nested signal to the generic Dynamic end (success/failure, only).
          # Note that here we lose information about what specific event was emitted.
          [
            signal.kind_of?(Railway::End::Success) ? @outputs.keys[0] : @outputs.keys[1],
            args
          ]
        end
      end
    end
  end # Operation
end
