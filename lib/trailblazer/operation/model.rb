class Trailblazer::Operation
  module Model
    def self.included(includer)
      includer.extend DSL # ::model
      includer.include BuildMethods # model! and friends.
      includer.& Build, after: "operation.new", name: "model.build"
    end

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
    end

    # Include this if you only want to override #model! and provide your own model
    # building logic. It will be run after "operation.new".
    module Builder
      def self.included(includer)
        includer.> Model::Build, after: "operation.new", name: "model.build"
      end
    end

  # Methods to create the model according to class configuration and params.
    module BuildMethods
      def model_class
        self["model.class"] or raise "[Trailblazer] You didn't call Operation::model."
      end

      def action_name
        self["model.action"] or :create
      end

      def model!(params)
        instantiate_model(params)
      end

      def instantiate_model(params)
        send("#{action_name}_model", params)
      end

      def create_model(params)
        model_class.new
      end

      def update_model(params)
        model_class.find(params[:id])
      end

      alias_method :find_model, :update_model

      # Doesn't throw an exception and will return false to divert to Left.
      def find_by_model(params)
        model = model_class.find_by(id: params[:id]) and return model
        self["model.result.failure?"] = true
        false
      end
    end
  end

  # calls operation.model!(params).
  Model::Build  = ->(input, options) { options["model"] = input.model!(options["params"]) }
end
