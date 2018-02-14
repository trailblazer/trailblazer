class Trailblazer::Operation

  # false is automatically connected to End.failure.

  def self.Wrap(user_wrap, id: "Wrap/#{rand(100)}", &block)
    operation_class = Wrap.create_operation(block)
    wrapped         = Wrap::Wrapped.new(operation_class, user_wrap)

    # connect `false` as an end event, when an exception stopped the wrap, for example.

    { task: wrapped, id: id, outputs: operation_class.outputs }
    # TODO: Nested could have a better API and do the "merge" for us!
  end

  module Wrap
    def self.create_operation(block)
      Class.new( Nested.operation_class, &block ) # Usually resolves to Trailblazer::Operation.
    end

    # behaves like an operation so it plays with Nested and simply calls the operation in the user-provided block.
    class Wrapped #< Trailblazer::Operation # FIXME: the inheritance is only to satisfy Nested( Wrapped.new )
      include Trailblazer::Activity::Interface

      def initialize(operation, user_wrap)
        @operation  = operation
        @user_wrap  = user_wrap
      end

      def call( (options, flow_options), **circuit_options )
        block_calling_wrapped = -> {
          activity = @operation.to_h[:activity]

          activity.( [options, flow_options], **circuit_options )
        }

        # call the user's Wrap {} block in the operation.
        # This will invoke block_calling_wrapped above if the user block yields.
        returned = @user_wrap.( options, flow_options, **circuit_options, &block_calling_wrapped )

        # returned could be
        #  1. the 1..>=3 Task interface result
        #  2. false
        #  3. true or something else, but not the Task interface (when rescue isn't needed)

        # legacy outcome.
        # FIXME: we *might* return some "older version" of options here!
        if returned === false
          return @operation.outputs[:failure].signal, [options, flow_options]
        elsif returned === true
          return @operation.outputs[:success].signal, [options, flow_options]
        end

        returned # let's hope returned is one of activity's Ends.
      end

      def outputs
        @operation.outputs # FIXME: we don't map false, yet
      end
    end
  end # Wrap
end

# (options, *) => (options, operation, bla)
# (*, params:, **) => (options, operation, bla, options)
