module Trailblazer
  class Operation
    class DeprecatedOptions < Trailblazer::Circuit::Task::Args
      def self.call!(proc, direction, options, flow_options, *args)
        if proc.is_a?(Proc)
          return proc.(options) if proc.arity == 1
        else
          return proc.(options) if proc.method(:call).arity == 1
        end

        super
      end
    end

  end
end
