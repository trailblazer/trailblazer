class Trailblazer::Operation
  module Model
    # Imports ::model and ::action into an operation.
    module DSL
      def self.extended(extender)
        extender.extend Uber::InheritableAttr
        extender.inheritable_attr :config
        extender.config = {}
      end

      def model(name, action=nil)
        self.config[:model] = name
        action(action) if action # coolest line ever.
      end

      def action(name)
        self.config[:action] = name
      end

      def action_name # considered private.
        self.config[:action] or :create
      end

      def model_class # considered private.
        self.config[:model] or raise "[Trailblazer] You didn't call Operation::model."
      end
    end
  end
end