class Trailblazer::Operation
  def self.Wrap(user_wrap, id: "Wrap/#{rand(100)}", &block)
    operation_class = Wrap.create_operation(block)
    wrapped         = Wrap::Wrapped.new(operation_class, user_wrap)

    { task: wrapped, id: id, outputs: operation_class.outputs }
  end

  module Wrap
    def self.create_operation(block)
      Class.new( Nested.operation_class, &block ) # Usually resolves to Trailblazer::Operation.
    end

    # behaves like an operation so it plays with Nested and simply calls the operation in the user-provided block.
    class Wrapped #< Trailblazer::Operation # FIXME: the inheritance is only to satisfy Nested( Wrapped.new )
      include Trailblazer::Activity::Interface

      private def deprecate_positional_wrap_signature(user_wrap)
        parameters = user_wrap.is_a?(Class) ? user_wrap.method(:call).parameters : user_wrap.parameters

        return user_wrap if parameters[0] == [:req] # means ((ctx, flow_options), *, &block), "new style"

        ->((ctx, flow_options), **circuit_options, &block) do
          warn "[Trailblazer] Wrap handlers have a new signature: ((ctx), *, &block)"
          user_wrap.(ctx, &block)
        end
      end

      def initialize(operation, user_wrap)
        user_wrap = deprecate_positional_wrap_signature(user_wrap)

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
        returned = @user_wrap.( [ctx, flow_options], **circuit_options, &block_calling_wrapped )

        # {returned} can be
        #   1. {circuit interface return} from the begin block, because the wrapped OP passed
        #   2. {task interface return} because the user block returns "customized" signals, true of fale

        if returned.is_a?(Array) # 1. {circuit interface return}, new style.
          signal, (ctx, flow_options) = returned
        else                     # 2. {task interface return}, only a signal (or true/false)
          # TODO: deprecate this?
          signal = returned
        end

        # Use the original {signal} if there's no mapping.
        # This usually means signal is an End instance or a custom signal.
        signal = @signal_to_output.fetch(signal, signal)

        return signal, [ctx, flow_options]
      end

      def outputs
        @operation.outputs
      end
    end
  end # Wrap
end
