module Trailblazer
  class NotAuthorizedError < RuntimeError
  end

  module Operation::Policy
    def self.included(includer)
      includer.extend Uber::InheritableAttr
      includer.inheritable_attr :policy_class
      includer.extend ClassMethods
    end

    module ClassMethods
      def policy(*args, &block)
        self.policy_class = block
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
        includer.send(:include, EvaluatePolicy)
      end

      module ClassMethods
        def policy(policy_class, action)
          self.policy_class = [policy_class, action]
        end
      end

      attr_reader :policy

      module EvaluatePolicy
      private
        def evaluate_policy(params)
          class_name, action = self.class.policy_class
          @policy = class_name.new(params[:current_user], model)

          # DISCUSS: this flow should be used via pundit's API, which we might have to extend.
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