class Trailblazer::Operation
  module Policy
    def self.included(includer)
      includer.extend DSL
      includer.| Evaluate, before: Call
    end

    module DSL
      def policy(*args, &block)
        heritage.record(:policy, *args, &block)

        self["policy.evaluator"] = build_permission(*args, &block)
      end

      # To be overridden by your policy strategy.
      def build_permission(*args, &block)
        Permission.new(*args, &block)
      end
    end

    # This can be subclassed for other policy strategies, e.g. non-pundit Authsome.
    class Permission
      def initialize(policy_class, action)
        @policy_class, @action = policy_class, action
      end

      def call(skills, params)
        policy = build_policy(skills, params) # here, this translates to Pundit interface.

        if policy.send(@action)
          return { "policy" => policy, valid: true }
        else
          return { "policy" => policy, valid: false, "message" => "Breach" }
        end
      end

    private
      def build_policy(skills, params)
        @policy_class.new(skills["user.current"], skills["model"])
      end
    end
  end

  # This is a generic evaluate function for all kinds of policies.
  # All the call'able evaluator has to do is returning a hash result.
  Policy::Evaluate = ->(input, options) {
    result                     = options[:skills]["policy.evaluator"].(input, options[:skills]["params"]) # DISCUSS: do we actually have to pass params?
    options[:skills]["policy"] = result["policy"] # assign the policy as a skill.
    options[:skills]["policy.result"] = result

    # flow control
    return ::Pipetree::Stop unless result[:valid]
    input
  }
end
