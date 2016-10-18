require "trailblazer/operation/setup"

module Trailblazer
  # Policy::Guard is a very simple policy implementation.
  # It adds #evaluate_policy to Operation#setup! and calls whatever
  # you provided to ::policy.
  #
  # http://trailblazer.to/gems/operation/policy.html#guard
  module Operation::Policy
    module Guard
      def self.included(includer)
        includer.include Operation::Setup
        includer.include Setup # Policy::Setup, let's wait for pipetree to have this nice.
        includer.extend(DSL) # Provides ::policy(CallableObject)
        includer.extend(ClassMethods)

        require "trailblazer/operation/competences"
        includer.include Trailblazer::Operation::Competences

        includer.extend Declarative::Heritage::Inherited
        includer.extend Declarative::Heritage::DSL
      end

      module ClassMethods
        def policy(callable=nil, &block)
          heritage.record(:policy, callable, &block)

          self["policy.evaluator"] = Uber::Options::Value.new(callable || block)
        end
      end

      def evaluate_policy(params)
        call_policy(params) or raise policy_exception
      end

      # Override if you want your own policy invocation, e.g. with more args.
      def call_policy(params)
        return true unless self["policy.evaluator"] # WE NEED THE KEANU REAVES OPERATIOOOOOOOR!
        self["policy.evaluator"].(self, params)
      end

      def policy_exception
        NotAuthorizedError.new
      end
    end
  end
end
