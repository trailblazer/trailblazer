class Trailblazer::Operation
  Base = self # TODO: we won't need this with 2.1.

  def self.Wrap(user_wrap, &block)
    # TODO: immutable API for creating operations. Operation.build(step .. , step ..)
    operation_class = Class.new(Base)
    operation_class.instance_exec(&block) # evaluate the wrapped operation code.

    step = Wrap.Task(user_wrap, operation_class) # FIXME: must return Nested

    [ step, {}, {} ]
  end

  module Wrap
    def self.Task(user_wrap, operation_class)
      ->(direction, options, flow_options) {

        # This block is passed to the user's wrap. It's invoked when the user_wrap calls `yield`.
        default_block = ->{ # runs the Wrap'ped operation_class.
          _options, _flow_options = Railway::TaskWrap.arguments_for_call(operation_class, direction, options, flow_options)

          # here, an exception could happen. they are usually caught in the user_wrap.
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
