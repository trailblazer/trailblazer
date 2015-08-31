module Trailblazer
  class NotAuthorizedError < RuntimeError
  end

  module Operation::Policy
    def self.included(includer)
      includer.extend Uber::InheritableAttr
      includer.inheritable_attr :policy_config
      includer.extend ClassMethods
    end

    module ClassMethods
      def policy(*args, &block)
        self.policy_config = block
      end
    end

  private
    def setup!(params)
      super
      evaluate_policy(params)
    end

    def evaluate_policy(params)
      policy_block = self.class.policy_config or return
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
          self.policy_config = [policy_class, action]
        end
      end

      attr_reader :policy


      module BuildPolicy
        def build_policy_for(params, class_name)


          class_name.new(params[:current_user], model)
        end

        # def policy(policy_class=self.policy_class)

        # end
      end
      include BuildPolicy

      module EvaluatePolicy
      private
        def evaluate_policy(params)
          class_name, action = policy_class

          return true unless class_name

          @policy = build_policy_for(params, class_name) or return true

          # DISCUSS: this flow should be used via pundit's API, which we might have to extend.
          @policy.send(action) or raise ::Pundit::NotAuthorizedError.new(query: action, record: model, policy: @policy)
        end
      end

      def policy_class
        self.class.policy_config
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