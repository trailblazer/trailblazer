class Trailblazer::Operation
  module Policy
    module Pundit
      extend Macro

      def self.import!(operation, import, policy_class, action, options={})
        Policy.add!(operation, import, options) { Pundit.build(policy_class, action) }
      end

      def self.build(*args, &block)
        Condition.new(*args, &block)
      end

      # Pundit::Condition is invoked at runtime when iterating the pipe.
      class Condition
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
          @policy_class.new(skills["current_user"], skills["model"])
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
