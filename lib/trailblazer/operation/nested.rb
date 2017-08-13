# when __call__ing a nested op, in 2.0 the call would create a new skill with Skill(incoming_options, self.skills)
# we now have to create this manually.  maybe this should be done in __call__ ?


# per default, everything we pass into a circuit is immutable. it's the ops/act's job to allow writing (via a Context)

class Trailblazer::Operation
  def self.Nested(callable, input:nil, output:nil, name: "Nested(#{callable})")
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

    [ task, { name: name }, {}, activity_outputs ]
  end

  # WARNING: this is experimental API, but it will end up with something like that.
  module Element
    # DISCUSS: add builders here.
    def initialize(wrapped=nil)
      @wrapped = wrapped
    end

    module Dynamic
      def initialize(wrapped)
        @wrapped = Trailblazer::Option::KW(wrapped)
      end
    end
  end

  module Nested
    module Nestable
    end

    # Please note that the instance_variable_get are here on purpose since the
    # superinternal API is not entirely decided, yet.
    # @api private
    def self.build(nested_operation, input, output, is_nestable_object=method(:nestable_object?)) # DISCUSS: use builders here?
      # TODO: this will be done via incoming/outgoing contracts.
      # options_for_nested = Input.new
      # options_for_nested = Input::Dynamic.new(input) if input # FIXME: they need to have symbol keys!!!!

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
      include Element::Dynamic

      def initialize(*)
        super
        @end_events = [ Railway::End::Success.new(:success), Railway::End::Failure.new(:failure) ]
      end

      attr_reader :end_events

      def __call__(direction, options, flow_options)
        activity = @wrapped.(options, flow_options) # evaluate the option to get the actual "object" to call.

        direction ||= activity.instance_variable_get(:@start) # FIXME. we're assuming the object is an Activity.

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
      include Element

      def call(context, options)
        options
      end

      class RuntimeOnly
        include Element

        # Per default, only runtime data for nested operation.
        def call(operation, options)
          # this must return a Skill.
          # Trailblazer::Skill::KeywordHash options.to_runtime_data[0]

          # DISCUSS: are we doing the right thing here?

          original, mutable = options.decompose

          original

          Trailblazer::Context::Immutable.new(Trailblazer::Context(original))
        end
      end

      class Dynamic
        include Element#::Dynamic

        def call(operation, options)
          # Trailblazer::Skill::KeywordHash @wrapped.(operation, options, runtime_data: options.to_runtime_data[0], mutable_data: options.to_mutable_data )
          original, mutable = options.decompose

          # DISCUSS: how to allow tmp injections?
          # FIXME: almost identical with Option::KW.
          @wrapped.( options, **options.to_hash.merge(
            runtime_data: Trailblazer::Context::Immutable.new(original),
            mutable_data: Trailblazer::Context::Immutable.new(mutable)
          ) )
        end
      end

      # Outgoing options, the returned options set when calling a nested task.
      # @note This will be replaced with an outgoing options mapping in the TaskWrap in TRB 2.2.
      class Output
        include Element

        def call(input, options, result)
          mutable_data_for(result).each { |k,v| options[k] = v }
        end

        def mutable_data_for(result)
          options = result[1]

          original, mutable = options.decompose

          mutable
        end

        class Dynamic < Output
          include Element#::Dynamic

          def call(input, options, result)
            @wrapped.( options, mutable_data: mutable_data_for(result))
          end
        end
      end
    end
  end
end

