module Trailblazer
  class NotAuthorizedError < RuntimeError
  end

  module Operation::Policy
    def self.included(includer)
      includer.extend Uber::InheritableAttr
      includer.inheritable_attr :policy_config
      includer.policy_config = []
      includer.extend ClassMethods
    end

    module ClassMethods
      def policy(*args, &block)
        self.policy_config = [block]
      end

      def policy_class
        policy_config.first
      end
    end

  private
    def setup!(params)
      super
      evaluate_policy(params)
    end

    def evaluate_policy(params)
      policy_block = self.class.policy_class or return
      instance_exec(params, &policy_block) or raise NotAuthorizedError.new
    end





    require "pundit"
    module Pundit
      def self.included(includer)
        includer.send(:include, Trailblazer::Operation::Policy)
        includer.extend ClassMethods
        includer.extend BuildPolicy # so we can use ::build_policy in builders.
        includer.send(:include, EvaluatePolicy)
      end

      module ClassMethods
        def policy(policy_class, action)
          self.policy_config = [policy_class, action]
        end
      end

      attr_reader :policy


      module BuildPolicy
        def build_policy(model, params, class_name=self.policy_class)
          return unless class_name

          build_policy_for(params, model, class_name)
        end

        def build_policy_for(params, model, class_name)
          class_name.new(params[:current_user], model)
        end
      end
      include BuildPolicy


      module EvaluatePolicy
      private
        def evaluate_policy(params)
          @policy = build_policy(model, params, self.class.policy_class) or return true

          # DISCUSS: this flow should be used via pundit's API, which we might have to extend.
          action = self.class.policy_config.last
          @policy.send(action) or raise ::Pundit::NotAuthorizedError.new(query: action, record: model, policy: @policy)
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