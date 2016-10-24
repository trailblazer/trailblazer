class Trailblazer::Operation
  module Policy
    def self.included(includer)
      includer.extend DSL
      includer.| Evaluate, before: Call
      includer.| Assign, after: Evaluate
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

    class Permission
      def initialize(policy_class, action)
        @policy_class, @action = policy_class, action
      end

      # Without a block, return the policy object (which is usually a Pundit-style class).
      # When block is passed evaluate the default rule and run block when false.
      def call(user, model)
        policy = build_policy(user, model)

        policy.send(@action) || yield(policy, @action) if block_given?

        policy
      end

    private
      def build_policy(user, model)
        @policy_class.new(user, model)
      end
    end
  end

  # TODO: make generic, or even unnecessary.
  Policy::Assign = ->(input, options) { options[:skills]["policy"] = options[:policy]; input }

  # "current_user" is now a skill dependency, not a params option anymore.
  Policy::Evaluate = ->(input, options) {
      # raise options[:skills]["model"].inspect
      options[:policy] = options[:skills]["policy.evaluator"].(options[:skills]["user.current"], options[:skills]["model"]) {
        options[:skills][:valid] = false
        options[:skills]["policy.message"] = "Not allowed"
        return ::Pipetree::Stop }
      input
    }
end
