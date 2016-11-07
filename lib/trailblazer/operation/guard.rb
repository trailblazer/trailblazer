require "trailblazer/operation/policy" # FIXME.

class Trailblazer::Operation
  module Policy
    module Guard
      extend Stepable

      def self.import!(operation, user_proc)
        operation["pipetree"].& Evaluate,
          name:   "policy.guard.evaluate",
          before: "operation.result"

        operation["policy.evaluator"] = Guard.build_permission(user_proc)
      end

      # includer.& Evaluate, before: "operation.call", name: "policy.guard.evaluate"

      def self.build_permission(callable, &block)
        value = Uber::Options::Value.new(callable || block)

        # call'ing the Uber value will run either proc or block.
        # this gets wrapped in a Operation::Result object.
        ->(skills) { Result.new( value.(skills, skills), {} ) }
      end
    end # Guard
  end
end
