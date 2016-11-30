class Trailblazer::Operation
  module Policy
    # Step: This generically `call`s a policy and then pushes its result to skills.
    class Eval
      include Uber::Callable

      def initialize(name:, path:)
        @name = name
        @path = path
      end

      def call(input, options)
        condition = options[@path] # this allows dependency injection.
        result    = condition.(options)

        options["policy.#{@name}"]        = result["policy"] # assign the policy as a skill.
        options["result.policy.#{@name}"] = result

        # flow control
        result.success? # since we & this, it's only executed OnRight and the return boolean decides the direction, input is passed straight through.
      end
    end

    extend Macro

    def self.import!(operation, import, policy_class, action, options={})
      name = options[:name] || :default

      # configure class level.
      operation[path = "policy.#{name}.eval"] = Policy.build(policy_class, action)

      # add step.
      import.(:&, Eval.new( name: name, path: path ),
        name: path
      )
    end

    # includer.& Evaluate, before: "operation.call", name: "policy.evaluate"

    def self.build(*args, &block)
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
