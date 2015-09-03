module Trailblazer
  class NotAuthorizedError < RuntimeError
  end

  # Adds #evaluate_policy to Operation#setup!
  module Operation::Policy
    def self.included(includer)
      includer.inheritable_attr :policy_config
      includer.policy_config = Permission.new { true } # return true per default.
      includer.extend ClassMethods
    end

    module ClassMethods
      def policy(*args, &block)
        self.policy_config = permission_class.new(*args, &block)
      end

      def permission_class
        Permission
      end
    end

  private
    def setup!(params)
      super
      evaluate_policy(params)
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





    require "pundit"
    module Pundit
      class Permission
        def initialize(policy_class, action)
          @policy_class, @action = policy_class, action
        end

        def call(user, model)
          policy = policy(user, model)
          [policy.send(@action), policy]
        end

        def policy(user, model)
          @policy_class.new(user, model)
        end

      # private
        def action
          @action
        end
      end

      def self.included(includer)
        includer.send(:include, Trailblazer::Operation::Policy)
        includer.extend ClassMethods
        includer.extend BuildPolicy # so we can use ::build_policy in builders.
        includer.send(:include, EvaluatePolicy)
      end

      module ClassMethods
        def permission_class
          Permission
        end
      end

      attr_reader :policy


      module BuildPolicy
        def build_policy(model, params, permission=self.policy_config)
          permission.policy(params[:current_user], model)
        end
      end
      include BuildPolicy


      module EvaluatePolicy
      private
        def evaluate_policy(params)
          puts "@@@@@ #{self.class.policy_config.inspect}"
          result, @policy = self.class.policy_config.(params[:current_user], model)
          result or raise policy_exception(@policy, self.class.policy_config.action, model)
          # policy!(model, params, self.class.policy_config)

          # # DISCUSS: this flow should be used via pundit's API, which we might have to extend.
          # evaluate_policy!(@policy, action, model)
        end

        # def policy!(model, params, policy_class)
        #   @policy = build_policy(model, params, policy_class)
        # end

        # def evaluate_policy!(policy, action, model)
        #   policy.send(action) or raise policy_exception(policy, action, model)
        # end

        def policy_exception(policy, action, model)
          ::Pundit::NotAuthorizedError.new(query: action, record: model, policy: policy)
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