require "trailblazer/operation/policy" # FIXME.

class Trailblazer::Operation
  module Policy
    module Guard
      extend Stepable

      def self.import!(operation, pipe, user_proc)
        pipe.(:&, Evaluate, name: "policy.guard.evaluate")

        operation["policy.evaluator"] = Guard.build_permission(user_proc)
      end

      def self.build_permission(callable, &block)
        value = Uber::Options::Value.new(callable || block)

        # call'ing the Uber value will run either proc or block.
        # this gets wrapped in a Operation::Result object.
        ->(skills) { Result.new( value.(skills, skills), {} ) }
      end
    end # Guard
  end
end
