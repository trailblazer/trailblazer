class Trailblazer::Operation
  module Policy
    # This is a generic evaluate function for all kinds of policies.
    # Arguments to the Callable: (skills)
    Evaluate = ->(input, options) {
      result = options["policy.evaluator"].(options)

      options["policy"]        = result["policy"] # assign the policy as a skill.
      options["result.policy"] = result

      # flow control
      result.success? # since we & this, it's only executed OnRight and the return boolean decides the direction, input is passed straight through.
    }

    extend Stepable

    def self.import!(operation, policy_class, action)
      operation["pipetree"].& Evaluate,
        name:   "policy.evaluate"

      operation["policy.evaluator"] = Policy.build_permission(policy_class, action)
    end

    # includer.& Evaluate, before: "operation.call", name: "policy.evaluate"

    def self.build_permission(*args, &block)
      Permission.new(*args, &block)
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

      def result!(success, policy)
        data = { "policy" => policy }
        data["message"] = "Breach" if !success # TODO: how to allow messages here?

        Result.new(success, data)
      end
    end
  end
end

# how to have more than one policy, and then also replace its interpreter with another ? self.| MyInterpreter, replace: "Policy::Evaluator.after_validate"
