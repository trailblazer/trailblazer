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
    # NOTE: using a class here is faster than a simple proc: https://twitter.com/apotonick/status/791162989692891136
    #
    class Permission
      def initialize(policy_class, action)
        @policy_class, @action = policy_class, action
      end

      # Instantiate the actual policy object, and call it.
      def call(skills)
        policy = build_policy(skills)          # this translates to Pundit interface.
        result!(policy.send(@action), policy)
      end

    private
      def build_policy(skills)
        @policy_class.new(skills["user.current"], skills["model"])
      end

      # Note that in Trailblazer 2.1 we might have functions that "interpret" the result,
      # that are easier to hook in.
      def result!(result, policy)
        if result
          return { "policy" => policy, "valid" => true }
        else
          return { "policy" => policy, "valid" => false, "message" => "Breach" }
        end
      end
    end
  end

  # This is a generic evaluate function for all kinds of policies.
  # Arguments to the Callable: (skills)
  #
  # All the Callable evaluator has to do is returning a hash result.
  Policy::Evaluate = ->(input, options) {
    result                     = options["policy.evaluator"].(options)
    options["policy"] = result["policy"] # assign the policy as a skill.
    options["policy.result"] = result

    # flow control
    return ::Pipetree::Stop unless result["valid"]
    input
  }
end

# TODO: how could we add something like "log breach"?
# how to have more than one policy, and then also replace its interpreter with another ? self.| MyInterpreter, replace: "Policy::Evaluator.after_validate"
