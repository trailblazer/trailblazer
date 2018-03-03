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

        # Since in the user block, you can return Railway.pass! etc, we need to map
        # those to the actual wrapped operation's end.
        outputs           = @operation.outputs
        @signal_to_output = {
          Railway.pass!      => outputs[:success].signal,
          Railway.fail!      => outputs[:failure].signal,
          Railway.pass_fast! => outputs[:pass_fast].signal,
          Railway.fail_fast! => outputs[:fail_fast].signal,
          true               => outputs[:success].signal,
          false              => outputs[:failure].signal,
          nil                => outputs[:failure].signal,
        }
      end

      def call( (ctx, flow_options), **circuit_options )
        block_calling_wrapped = -> {
          activity = @operation.to_h[:activity]

          activity.( [ctx, flow_options], **circuit_options )
        }

        # call the user's Wrap {} block in the operation.
        # This will invoke block_calling_wrapped above if the user block yields.
        returned = @user_wrap.( ctx, flow_options, **circuit_options, &block_calling_wrapped )

        # {returned} can be
        #   1. {circuit interface return} from the begin block, because the wrapped OP passed
        #   2. {task interface return} because the user block returns "customized" signals, true of fale

        if returned.is_a?(Array) # 1. {circuit interface return}, new style.
          signal, (ctx, flow_options) = returned
        else                     # 2. {task interface return}, only a signal (or true/false)
          signal = returned
        end

        # Use the original {signal} if there's no mapping.
        # This usually means signal is an End instance or a custom signal.
        signal = @signal_to_output.fetch(signal, signal)

        return signal, [ctx, flow_options]
      end

      def outputs
        @operation.outputs # FIXME: we don't map false, yet
      end
    end
  end # Wrap
end

# (options, *) => (options, operation, bla)
# (*, params:, **) => (options, operation, bla, options)
