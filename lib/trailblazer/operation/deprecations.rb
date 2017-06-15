module Trailblazer
  class Operation
    class DeprecatedOptions < Trailblazer::Circuit::Task::Args
      def self.call!(proc, direction, options, flow_options, *args)
        if proc.is_a?(Proc)
          deprecate(proc)
          return proc.(options) if proc.arity == 1
        else
          deprecate(proc)
          return proc.(options) if proc.method(:call).arity == 1
        end

        super
      end

      def self.deprecate(proc)
        warn "[Trailblazer] Please use the step API `def my_step!(options, **)` for your step: #{proc}"
      end
    end

  end
end
