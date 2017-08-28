# per default, everything we pass into a circuit is immutable. it's the ops/act's job to allow writing (via a Context)
module Trailblazer
  class Operation
    def self.Nested(callable, input:nil, output:nil, name: "Nested(#{callable})")
      task_wrap_wirings = []

      task, operation = Nested.build(callable, input, output)

      # @needs operation#end_events

      end_events = operation.end_events

        # TODO: introduce Activity interface (for introspection, events, etc)
      activity_outputs =
        ::Hash[
          end_events.collect do |evt|
            _name = evt.instance_variable_get(:@name)
            [ evt, { role: _name } ] # this is a wild guess, e.g. PassFast => { role: :pass_fast }
          end
        ]

      default_input_filter  = ->(options, *) { ctx = options }
      default_output_filter = ->(options, *) { mutable = options }

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

      { task: task, node_data: { id: name }, runner_options: { alteration: task_wrap_wirings }, outputs: activity_outputs }
    end

    # @private
    module Nested
      module Nestable
      end

      def self.build(nested_operation, input, output, is_nestable_object=method(:nestable_object?)) # DISCUSS: use builders here?
        nested_activity = is_nestable_object.(nested_operation) ? nested_operation : Dynamic.new(nested_operation)

        # The returned {Nested} instance is a valid circuit element and will be `call`ed in the circuit.
        # It simply returns the nested activity's direction.
        # The actual wiring - where to go with that, is up to the Nested() macro.
        return Trailblazer::Activity::Nested(nested_activity, nil) do |activity:raise, start_at:nil, args:raise, **|
          activity.__call__( start_at, *args )
        end, nested_activity
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
          @wrapped    = Trailblazer::Option::KW(wrapped)
          @end_events = [ Railway::End::Success.new(:success), Railway::End::Failure.new(:failure) ]
        end

        attr_reader :end_events

        def __call__(direction, options, flow_options)
          activity = @wrapped.(options, flow_options) # evaluate the option to get the actual "object" to call.

          direction, options, flow_options = activity.__call__(direction, options, flow_options)

          # Translate the genuine nested direction to the generic Dynamic end (success/failure, only).
          # Note that here we lose information about what specific event was emitted.
          [
            direction.kind_of?(Railway::End::Success) ? end_events[0] : end_events[1],
            options,
            flow_options
          ]
        end
      end
    end
  end # Operation
end
