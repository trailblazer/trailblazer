class Trailblazer::Operation
  module Policy
    # Step: This generically `call`s a policy and then pushes its result to `options`.
    # You can use any callable object as a policy with this step.
    class Eval
      def initialize(name:nil, path:nil)
        @name = name
        @path = path
      end

      def call(input, options)
        condition = options[@path] # this allows dependency injection.
        result    = condition.(input, options)

        options["policy.#{@name}"]        = result["policy"] # assign the policy as a skill.
        options["result.policy.#{@name}"] = result

        # flow control
        result.success? # since we & this, it's only executed OnRight and the return boolean decides the direction, input is passed straight through.
      end
    end

    # Adds the `yield` result to the pipe and treats it like a
    # policy-compatible  object at runtime.
    def self.step(condition, options, &block)
      name = options[:name]
      path = "policy.#{name}.eval"

      step = Eval.new( name: name, path: path )
      step = Pipetree::Step.new(step, path => condition)

      [ step, name: path ]
    end
  end
end
