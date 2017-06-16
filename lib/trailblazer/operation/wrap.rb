class Trailblazer::Operation
  Base = self # TODO: we won't need this with 2.1.

  def self.Wrap(user_wrap, &block)
    # TODO: immutable API for creating operations.
    operation = Class.new(Base)
    operation.instance_exec(&block) # evaluate the wrapped operation code.

    step = Wrap.Task(user_wrap, operation) # FIXME: must return Nested

    [ step, {}, {} ]
  end

  module Wrap
    def self.Task(user_wrap, activity)
      ->(direction, options, flow_options) {

        # this block is invoked when the user_wrap calls `yield`.
        default_block = ->{ # runs the Wrap'ped operation.
          activity.__call__( activity[:Start], options, flow_options ) # here, an exception could happen. they are usually caught in the user code's Wrap'per.
        }

        # direction, options, flow_options = user_wrap.(options, flow_options[:exec_context], activity, &default_block )
        # call the user's wrap block. it returns true/false (ATM, but we can soon extend that to a Task interface).
        result = user_wrap.(options, flow_options[:exec_context], activity, &default_block )

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
