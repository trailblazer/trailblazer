module Trailblazer
# Adds #evaluate_policy to Operation#setup!
  module Operation::Policy
    module Guard
      def self.included(includer)
        includer.extend(DSL)
        includer.extend(ClassMethods)
        includer.send(:include, Setup)
      end

      module ClassMethods
        # Use Guard::Permission.
        def permission_class
          Permission
        end
      end

      def evaluate_policy(params)
        self.class.policy_config.(self, params) or raise NotAuthorizedError.new
      end

      # Encapsulates the operation's policy which is usually called in Op#setup!.
      class Permission
        def initialize(*args, &block)
          @callable, @args = Uber::Options::Value.new(block), args
        end

        def call(context, *args)
          @callable.(context, *args)
        end
      end
    end
  end
end