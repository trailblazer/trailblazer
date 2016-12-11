class Trailblazer::Operation
  module Policy
    # Step: This generically `call`s a policy and then pushes its result to `options`.
    # You can use any callable object as a policy with this step.
    class Eval
      include Uber::Callable

      def initialize(name:nil, path:nil)
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

    # Adds the `yield` result to the pipe and treats it like a
    # policy-compatible  object at runtime.
    def self.add!(operation, import, options, insert_options, &block)
      name = options[:name]
      path = options[:path]

      configure!(operation, import, options, &block)

      # add step.
      import.(:&, Eval.new( name: name, path: path ),
        insert_options.merge(name: path)
      )
    end

  private
    def self.configure!(operation, import, options)
      # configure class level.
      operation[ options[:path] ] = yield
    end
  end
end
