class Trailblazer::Operation
  # TODO: make Wrap::Subprocess not binary but actually wire its ends via the circuit.
  def self.Wrap(user_wrap, &block)
    operation_class = Wrap.build_wrapped_activity(block)
    step            = Wrap.build_task(user_wrap, operation_class) # FIXME: must return Nested

    [ step, {}, {} ]
  end

  module Wrap
    def self.build_wrapped_activity(block) # DISCUSS: this should be an activity at some point.
      # TODO: immutable API for creating operations. Operation.build(step .. , step ..)
      operation_class = Class.new( Nested.operation_class ) # Usually resolves to Trailblazer::Operation.
      operation_class.instance_exec(&block)                 # Evaluate the wrapped operation code (step definitions).
      operation_class
    end

    def self.build_task(user_wrap, operation_class)
      ->(direction, options, flow_options) {

        # This block is passed to the user's wrap. It's invoked when the user_wrap calls `yield`.
        # @return {Task interface}
          # TODO: this must simply be the activity/operation class which can be `call`ed. (Nested)
        default_block = ->{ # runs the Wrap'ped operation_class.
          _options, _flow_options = Railway::TaskWrap.arguments_for_call(operation_class, direction, options, flow_options)

          # here, an exception could happen. they are usually caught in the user_wrap.
          # we need to run Activity#call here so the original __call__ doesn't override :exec_context. this will be fixed
          # with call being a circuit itself.
          operation_class["__activity__"].( operation_class["__activity__"][:Start], _options, _flow_options )
        }

        # direction, options, flow_options = user_wrap.(options, flow_options[:exec_context], operation_class, &default_block )
        # call the user's wrap block. it returns true/false (ATM, but we can soon extend that to a Task interface).
        result = user_wrap.( options, flow_options[:exec_context], operation_class, &default_block )

        # DISCUSS: result can be [ Success/Failure, options, flow_options ] or false.

        [
          # direction.is_a?(Railway::End::Failure) ? Trailblazer::Circuit::Left : Trailblazer::Circuit::Right,
          result ? Trailblazer::Circuit::Right : Trailblazer::Circuit::Left,
          options,
          flow_options
        ]
      }
    end
  end # Wrap
end

# (options, *) => (options, operation, bla)
# (*, params:, **) => (options, operation, bla, options)
