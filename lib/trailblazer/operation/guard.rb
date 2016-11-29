require "trailblazer/operation/policy"
require "uber/option"

class Trailblazer::Operation
  module Policy
    module Guard
      extend Macro

      def self.import!(operation, import, user_proc)
        import.(:&, Evaluate, name: "policy.guard.evaluate")

        operation["policy.evaluator"] = Guard.build_permission(user_proc)
      end

      def self.build_permission(callable, &block)
        value = Uber::Option[callable || block]

        # call'ing the Uber::Option will run either proc or block.
        # this gets wrapped in a Operation::Result object.
        ->(options) { Result.new( value.(options), {} ) }
      end
    end # Guard
  end
end
