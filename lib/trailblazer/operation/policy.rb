module Trailblazer
  class NotAuthorizedError < RuntimeError
  end

  module Operation::Policy
    def self.included(includer)
      includer.extend Uber::InheritableAttr
      includer.inheritable_attr :policy_block
      includer.extend ClassMethods
    end

    module ClassMethods
      def policy(*args, &block)
        self.policy_block = block
      end
    end


  private
    def setup!(params)
      super
      evaluate_policy(params)
    end

    def evaluate_policy(params)
      policy_block = self.class.policy_block or return
      instance_exec(params, &policy_block) or raise NotAuthorizedError
    end





    require "pundit"
    module Pundit
      def self.included(includer)
        includer.extend ClassMethods
      end

      module ClassMethods
        def policy(policy_class, action, &block)
          @pundit_config = [policy_class, action]
          #@policies = [block]
        end

        attr_reader :pundit_config
      end

      def setup!(params)
        super
        # instance_exec params, &self.class.policies.first or raise NotAuthorizedError
        class_name, action = self.class.pundit_config
        policy = class_name.new(params[:current_user], model)

        # DISCUSS: this flow should be used via pundit's API, which we might have to extend.
        policy.send(action) or raise ::Pundit::NotAuthorizedError.new(query: action, record: model, policy: policy)
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