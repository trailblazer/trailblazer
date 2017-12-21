module Trailblazer
  class Operation
    class DeprecatedOptions < Option
      def self.call!(proc, direction, options, flow_options, *args)
        if proc.is_a?(Proc) && proc.arity == 1
          deprecate(proc)
          proc.(options)
        elsif proc.method(:call).arity == 1
          deprecate(proc)
          proc.(options)
        else
          super
        end
      end

      def self.deprecate(proc)
        warn "[Trailblazer] Please use the step API `def my_step!(options, **)` for your step: #{proc}"
      end
    end # DeprecatedOptions
  end
end
