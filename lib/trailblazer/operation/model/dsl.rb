class Trailblazer::Operation
  module Model
    # Imports ::model and ::action into an operation.
    module DSL
      def model(name, action=nil)
        heritage.record(:model, name, action)

        self["model.class"] = name
        action(action) if action # coolest line ever.
      end

      def action(name)
        heritage.record(:action, name)

        self["model.action"] = name
      end

      def action_name # considered private.
        self["model.action"] or :create
      end

      def model_class # considered private.
        self["model.class"] or raise "[Trailblazer] You didn't call Operation::model."
      end
    end
  end
end
