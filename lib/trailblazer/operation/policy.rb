module Trailblazer
  class NotAuthorizedError < RuntimeError
  end

  module Operation::Policy
    def self.included(includer)
      # includer.extend Uber::InheritableAttr
      # includer.inheritable_attr :_representer_class
      includer.extend ClassMethods
    end

    module ClassMethods
      def policy(*args, &block)
        @policies = [block]
      end

      attr_reader :policies
    end


    def setup!(params)
      super
      instance_exec params, &self.class.policies.first or raise NotAuthorizedError
      #
      # NotAuthorizedError.new(query: query, record: record, policy: policy)
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
end