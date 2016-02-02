module Trailblazer
  # Policy::Guard is a very simple policy implementation.
  # It adds #evaluate_policy to Operation#setup! and calls whatever
  # you provided to ::policy.
  #
  # http://trailblazer.to/gems/operation/policy.html#guard
  module Operation::Policy
    module Guard
      def self.included(includer)
        includer.extend(DSL) # Provides ::policy(CallableObject)
        includer.extend(ClassMethods)
        includer.send(:include, Setup)
      end

      module ClassMethods
        def policy(callable=nil, &block)
          self.policy_config = Uber::Options::Value.new(callable || block)
        end
      end

      def evaluate_policy(params)
        call_policy(params) or raise policy_exception
      end

      # Override if you want your own policy invocation, e.g. with more args.
      def call_policy(params)
        self.class.policy_config.(self, params)
      end

      def policy_exception
        NotAuthorizedError.new
      end
    end
  end
end
