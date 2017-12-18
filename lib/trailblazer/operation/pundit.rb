class Trailblazer::Operation
  module Policy
    def self.Pundit(policy_class, action, name: :default)
      Policy.step( Pundit.build(policy_class, action), name: name )
    end

    module Pundit
      def self.build(*args, &block)
        Condition.new(*args, &block)
      end

      # Pundit::Condition is invoked at runtime when iterating the pipe.
      class Condition
        def initialize(policy_class, action)
          @policy_class, @action = policy_class, action
        end

        # Instantiate the actual policy object, and call it.
        def call((options), *)
          policy = build_policy(options)          # this translates to Pundit interface.
          result!(policy.send(@action), policy)
        end

      private
        def build_policy(options)
          @policy_class.new(options[:current_user], options[:model])
        end

        def result!(success, policy)
          data = { "policy" => policy }
          data["message"] = "Breach" if !success # TODO: how to allow messages here?

          Result.new(success, data)
        end
      end
    end
  end
end
