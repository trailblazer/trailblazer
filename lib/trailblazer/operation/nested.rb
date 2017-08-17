# when __call__ing a nested op, in 2.0 the call would create a new skill with Skill(incoming_options, self.skills)
# we now have to create this manually.  maybe this should be done in __call__ ?


# per default, everything we pass into a circuit is immutable. it's the ops/act's job to allow writing (via a Context)

class Trailblazer::Operation
  def self.Nested(callable, input:nil, output:nil, name: "Nested(#{callable})")
    task_wrap_wirings = []

    task, operation = Nested.build(callable, input, output)

    # @needs operation#end_events

    end_events = operation.end_events

      # TODO: introduce Activity interface (for introspection, events, etc)
    activity_outputs =
      Hash[
        end_events.collect do |evt|
          _name = evt.instance_variable_get(:@name)
          [ evt, { role: _name } ] # this is a wild guess, e.g. PassFast => { role: :pass_fast }
        end
      ]


    default_output_filter = ->(options, *) { mutable = options }

      # TODO: move this to the generic step DSL
    # options_for_nested = Input.new
    # options_for_nested = Input::Dynamic.new(input) if input # FIXME: they need to have symbol keys!!!!
    if input
      input_task = Nested::Input.new(input, nil)
      task_wrap_wirings << [ :insert_before!, "task_wrap.call_task", node: [ input_task, id: ".input" ], incoming: Proc.new{true}, outgoing: [Trailblazer::Circuit::Right, {}] ]

      # FIXME: always add the decomposer:
      # task_wrap_wirings << [ :insert_before!, [:End, :default], node: [ output_task, id: ".output" ], incoming: Proc.new{true}, outgoing: [Trailblazer::Circuit::Right, {}] ]

      output ||= default_output_filter
    end

      # Default {Output} copies the mutable data from the nested activity into the original.
    if output
      output_task = Nested::Output.new( output, Nested::Output::CopyMutableToOriginal )

      task_wrap_wirings << [ :insert_before!, [:End, :default], node: [ output_task, id: ".output" ], incoming: Proc.new{true}, outgoing: [Trailblazer::Circuit::Right, {}] ]
    end



    [ task, { name: name }, { alteration: task_wrap_wirings }, activity_outputs ]
  end

  module Nested
    module Nestable
    end

    # Please note that the instance_variable_get are here on purpose since the
    # superinternal API is not entirely decided, yet.
    # @api private
    def self.build(nested_operation, input, output, is_nestable_object=method(:nestable_object?)) # DISCUSS: use builders here?
      # TODO: this will be done via incoming/outgoing contracts.
      #
      # options_for_composer = Input::Output.new
      # options_for_composer = Input::Output::Dynamic.new(output) if output


      nested_activity = is_nestable_object.(nested_operation) ? nested_operation : NonActivity.new(nested_operation)

      # The returned {Nested} instance is a valid circuit element and will be `call`ed in the circuit.
      # It simply returns the nested activity's direction.
      # The actual wiring - where to go with that, is up to the Nested() macro.
      # puts "@@@@@ #{nested_activity.inspect}"
      return Trailblazer::Circuit::Nested(nested_activity, nil) do |activity:raise, start_at:nil, args:raise, **|
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
    class NonActivity
      def initialize(wrapped)
        @wrapped = Trailblazer::Option::KW(wrapped)
        @end_events = [ Railway::End::Success.new(:success), Railway::End::Failure.new(:failure) ]
      end

      attr_reader :end_events

      def __call__(direction, options, flow_options)
        activity = @wrapped.(options, flow_options) # evaluate the option to get the actual "object" to call.

        direction, options, flow_options = activity.__call__(direction, options, flow_options)

        # Translate the genuine nested direction to the generic NonActivity end (success/failure, only).
        # Note that here we lose information about what specific event was emitted.
        [
          direction.kind_of?(Railway::End::Success) ? end_events[0] : end_events[1],
          options,
          flow_options
        ]
      end
    end

    # Ingoing options when calling a nested task.
    # @note This will be replaced with an ingoing options mapping in the TaskWrap in TRB 2.2.
    class Input
      def initialize(filter, strategy)
        @filter   = Trailblazer::Option(filter)
        @strategy = strategy
      end

      def call(direction, options, flow_options, task_conf, original_flow_options)
        # Trailblazer::Skill::KeywordHash @wrapped.(operation, options, runtime_data: options.to_runtime_data[0], mutable_data: options.to_mutable_data )
        # FIXME: almost identical with Option::KW.
        input_ctx = @filter.( options, original_flow_options )

        # TODO: is Context of hash?

        return direction, input_ctx, flow_options, task_conf.merge( original_context: options ), original_flow_options
      end
    end

    class Output < Input
      def call(direction, options, flow_options, task_conf, *args)
        original, options_for_filter = options.decompose

        output = @filter.(options_for_filter, **flow_options)       # this hash will get merged into options, per default.
        ctx    = @strategy.( task_conf[:original_context], output ) # here, we compute the "new" options {Context}.

        return direction, ctx, flow_options, task_conf, *args       # and then pass on the "new" context.
      end

      # "merge" Strategy
      class CopyMutableToOriginal
        # @param original Context
        # @param options  Context The object returned from a (nested) {Activity}.
        def self.call(original, mutable)
          mutable.each { |k,v| original[k] = v }

          original
        end
      end
    end
  end
end

