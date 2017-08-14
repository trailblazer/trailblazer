require "trailblazer/operation/nested"

class Trailblazer::Operation
  # TODO: make Wrap::Subprocess not binary but actually wire its ends via the circuit.

  def self.Wrap(user_wrap, &block)
    operation_class = Wrap.build_wrapped_activity(block)

    Nested( Wrap::Wrapped.new(operation_class, user_wrap) )
  end

  module Wrap
    # behaves like an operation so it plays with Nested and simply calls the operation in the user-provided block.
    class Wrapped #< Trailblazer::Operation # FIXME: the inheritance is only to satisfy Nested( Wrapped.new )
      include Nested::Nestable

      def initialize(activity, user_wrap)
        @activity   = activity
        @user_wrap  = user_wrap
      end

      # The __call__ method is invoked by Nested.
      def __call__(direction, options, flow_options)
        block_calling_wrapped = -> {
          args = Railway::TaskWrap.arguments_for_call(@activity, direction, options, flow_options)

          @activity["__activity__"].( direction, *args )
        }


        returned = @user_wrap.( options, flow_options[:exec_context], &block_calling_wrapped )

        # returned could be
        #  1. the 1..>=3 Task interface result
        #  2. false
        #  3. true or something else, but not the Task interface (when rescue isn't needed)

        # legacy outcome.
        # FIXME: we return some "older version" of options here!
        # FIXME: make sure end_events[1] is the Failure end!
        return  end_events[1], options, flow_options if false === returned


        # TODO: test a proper return in the user_block!!!

        returned # let's hope returned is one of activity's Ends.
      end

      def end_events
        @activity.end_events # FIXME: we don't map false, yet
      end
    end

    def self.build_wrapped_activity(block) # DISCUSS: this should be an activity at some point.
      # TODO: immutable API for creating operations. Operation.build(step .. , step ..)
      operation_class = Class.new( Nested.operation_class ) # Usually resolves to Trailblazer::Operation.
      operation_class.instance_exec(&block)                 # Evaluate the wrapped operation code (step definitions)

      operation_class
    end
  end # Wrap
end

# (options, *) => (options, operation, bla)
# (*, params:, **) => (options, operation, bla, options)
