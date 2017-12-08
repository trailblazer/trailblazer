require "trailblazer/operation/nested"

class Trailblazer::Operation

  # false is automatically connected to End.failure.

  def self.Wrap(user_wrap, &block)
    operation_class = Wrap.build_wrapped_activity(block)

    macro_options = Nested( Wrap::Wrapped.new(operation_class, user_wrap) )

    # connect `false` as an end event, when an exception stopped the wrap, for example.

    macro_options.merge(
      outputs:        macro_options[:outputs].merge( false => { role: :failure } )
    )

    # TODO: Nested could have a better API and do the "merge" for us!
  end

  module Wrap
    def self.build_wrapped_activity(block) # DISCUSS: this should be an activity at some point.
      # TODO: immutable API for creating operations. Operation.build(step .. , step ..)
      operation_class = Class.new( Nested.operation_class ) # Usually resolves to Trailblazer::Operation.
      operation_class.instance_exec(&block)                 # Evaluate the wrapped operation code (step definitions)
      operation_class
    end

    # behaves like an operation so it plays with Nested and simply calls the operation in the user-provided block.
    class Wrapped #< Trailblazer::Operation # FIXME: the inheritance is only to satisfy Nested( Wrapped.new )
      include Trailblazer::Activity::Interface

      def initialize(activity, user_wrap)
        @activity   = activity
        @user_wrap  = user_wrap
      end

      # The __call__ method is invoked by Nested.
      def __call__((options, flow_options), **circuit_options)
        block_calling_wrapped = -> {
          args, new_circuit_options = Railway::TaskWrap.arguments_for_call(@activity, [options, flow_options], **circuit_options)

          @activity["__activity__"].( args, circuit_options.merge( new_circuit_options ) ) # FIXME: arguments_for_call don't return the full circuit_options, :exec_context gets lost.
        }


        returned = @user_wrap.( options, flow_options, **circuit_options, &block_calling_wrapped )

        # returned could be
        #  1. the 1..>=3 Task interface result
        #  2. false
        #  3. true or something else, but not the Task interface (when rescue isn't needed)

        # legacy outcome.
        # FIXME: we *might* return some "older version" of options here!
        return false, [options, flow_options] if returned === false

        returned # let's hope returned is one of activity's Ends.
      end

      def outputs
        @activity.outputs # FIXME: we don't map false, yet
      end
    end
  end # Wrap
end

# (options, *) => (options, operation, bla)
# (*, params:, **) => (options, operation, bla, options)
