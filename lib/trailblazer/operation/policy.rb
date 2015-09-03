module Trailblazer
  class NotAuthorizedError < RuntimeError
  end

  # Adds #evaluate_policy to #setup!, and ::policy.
  module Operation::Policy
    def self.included(includer)
      includer.extend DSL
      includer.extend BuildPolicy # so we can use ::build_policy in builders.
      includer.send(:include, EvaluatePolicy)
    end

    module DSL
      def self.extended(extender)
        extender.inheritable_attr :policy_config
        extender.policy_config = Guard::Permission.new { true } # return true per default.
      end

      def policy(*args, &block)
        self.policy_config = permission_class.new(*args, &block)
      end

      def permission_class
        Permission
      end
    end

    attr_reader :policy

  private
    module Setup
      def setup!(params)
        super
        evaluate_policy(params)
      end
    end
    include Setup

    module BuildPolicy
      def build_policy(model, params, permission=self.policy_config)
        permission.policy(params[:current_user], model)
      end
    end
    include BuildPolicy


    module EvaluatePolicy
    private
      def evaluate_policy(params)
        result, @policy, action = self.class.policy_config.(params[:current_user], model)

        result or raise policy_exception(@policy, action, model)
      end

      def policy_exception(policy, action, model)
        NotAuthorizedError.new(query: action, record: model, policy: policy)
      end
    end

    # Encapsulate building the Policy object and calling the defined query action.
    class Permission
      def initialize(policy_class, action)
        @policy_class, @action = policy_class, action
      end

      def call(user, model)
        policy = policy(user, model)
        [policy.send(@action), policy, @action]
      end

      def policy(user, model)
        @policy_class.new(user, model)
      end
    end
  end

  # Adds #evaluate_policy to Operation#setup!
  module Operation::Policy
    module Guard
      def self.included(includer)
        includer.extend(Trailblazer::Operation::Policy::DSL)
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


  module Operation::Deny
    def self.included(includer)
      includer.extend ClassMethods
    end

    module ClassMethods
      def deny!
        raise NotAuthorizedError
      end
    end
  end
end