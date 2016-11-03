require "trailblazer/operation/policy" # FIXME.

class Trailblazer::Operation
  module Policy
    module Guard
      def self.included(includer)
        includer.extend DSL # ::policy
        includer.extend BuildPermission
        includer.& Evaluate, before: "operation.call", name: "policy.guard.evaluate"
      end

      module BuildPermission
        # Simply return a proc that, when called, evaluates the Uber:::Value.
        def build_permission(callable, &block)
          value = Uber::Options::Value.new(callable || block)

          # call'ing the Uber value will run either proc or block.
          # this gets wrapped in a Operation::Result object.
          ->(skills) { Result.new( value.(skills, skills), {} ) }
        end
      end
    end
  end
end
