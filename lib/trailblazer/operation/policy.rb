class Trailblazer::Operation
  module Policy
    # Step: This generically `call`s a policy and then pushes its result to `options`.
    # You can use any callable object as a policy with this step.
    class Eval
      def initialize(name:nil, path:nil)
        @name = name
        @path = path
      end

      # incoming low-level {Task API}.
      # outgoing Task::Binary API.
      def call((options, flow_options), **circuit_options)
        condition = options[ @path ] # this allows dependency injection.
        result    = condition.( [options, flow_options], **circuit_options )

        options["policy.#{@name}"]        = result["policy"] # assign the policy as a skill.
        options["result.policy.#{@name}"] = result

        # flow control
        signal = result.success? ? Trailblazer::Circuit::Right : Trailblazer::Circuit::Left # since we & this, it's only executed OnRight and the return boolean decides the direction, input is passed straight through.

        [ signal, [options, flow_options] ]
      end
    end

    # Adds the `yield` result to the pipe and treats it like a
    # policy-compatible  object at runtime.
    def self.step(condition, options, &block)
      name = options[:name]
      path = "policy.#{name}.eval"

      task = Eval.new( name: name, path: path )

      runner_options = {
        alteration: Trailblazer::Activity::Wrap::Inject::Defaults(
          path => condition
        )
      }

      { task: task, node_data: { id: path }, runner_options: runner_options }
    end
  end
end
