require "trailblazer/operation/policy" # FIXME.

module Trailblazer::Operation::Policy
  module Guard
    def self.included(includer)
      includer.extend DSL # ::policy
      includer.extend BuildPermission
      includer.& Evaluate, before: Trailblazer::Operation::Call
    end

    module BuildPermission
      # Simply return a proc that, when called, evaluates the Uber:::Value.
      def build_permission(callable, &block)
        value = Uber::Options::Value.new(callable || block)
        # call'ing the Uber value will run either proc or block.
        ->(skills) { { "valid" => value.(skills, skills) } }
      end
    end
  end
end
