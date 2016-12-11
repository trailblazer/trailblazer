class Trailblazer::Operation
  module Policy
    module Pundit
      def self.import!(operation, import, policy_class, action, options={}, insert_options={})
        Policy.add!(operation, import, options, insert_options) { Pundit.build(policy_class, action) }
      end

      def self.override!(*args, options)
        Pundit.import!(*args, options, replace: options[:path])
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

    def self.Pundit(policy, condition, name: :default, &block)
      options = {
        name:  name,
        path: "policy.#{name}.eval",
      }

      [Pundit, [policy, condition, options], block]
    end
  end
end
