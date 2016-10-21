require "trailblazer/operation/policy/guard"

module Trailblazer
  class NotAuthorizedError < RuntimeError
  end

  # Adds #evaluate_policy to #setup!, and ::policy.
  #
  # Needs #[], #[]= skill dependency.
  module Operation::Policy
    def self.included(includer)
      includer.include Operation::Setup
      includer.include Setup
      includer.extend DSL

              includer.extend Declarative::Heritage::Inherited
        includer.extend Declarative::Heritage::DSL
    end

    module DSL
      def policy(*args, &block)
        heritage.record(:policy, *args, &block)

        self["policy.evaluator"] = permission_class.new(*args, &block)
      end

      def permission_class
        Permission
      end
    end

    attr_reader :policy

  private
    module Setup
      # DISCUSS: this will be movable in TRB-pipetree.
      def setup!(params)
        evaluate_policy(super)
      end
    end

    def evaluate_policy(params)
      user = params[:current_user] # FIXME: this must be a competence.

      return true unless self["policy.evaluator"] # TODO: this could be handled nicer.

      @policy = self["policy.evaluator"].(user, model, @policy) do |policy, action|
        raise policy_exception(policy, action, model)
      end
    end

    def policy_exception(policy, action, model)
      NotAuthorizedError.new(query: action, record: model, policy: policy)
    end

    # Encapsulate building the Policy object and calling the defined query action.
    # This assumes the policy class is "pundit-style", as in Policy.new(user, model).edit?.
    class Permission
      def initialize(policy_class, action)
        @policy_class, @action = policy_class, action
      end

      # Without a block, return the policy object (which is usually a Pundit-style class).
      # When block is passed evaluate the default rule and run block when false.
      def call(user, model, external_policy=nil)
        policy = build_policy(user, model, external_policy)

        policy.send(@action) || yield(policy, @action) if block_given?
        policy
      end

    private
      def build_policy(user, model, policy)
        policy or @policy_class.new(user, model)
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
