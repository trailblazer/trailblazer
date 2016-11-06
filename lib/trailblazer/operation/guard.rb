require "trailblazer/operation/policy" # FIXME.

class Trailblazer::Operation
  module Policy
    module Guard
      #-- import!
      def self.[](proc)
        {
              step: Evaluate, # TODO: with different names?
              name: "policy.guard.evaluate",
            skills: { "policy.evaluator" => Guard.build_permission(proc) },
          operator: :&,
        }
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
