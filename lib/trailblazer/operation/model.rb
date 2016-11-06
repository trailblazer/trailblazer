class Trailblazer::Operation
  module Model
    #- import!
    # when imported via Operation::<>
    # This is the preferred mechanism in TRB2.
    def self.[](model_class, action=nil)
      if action.nil?
        # FIXME: prototyping inheritance. should we handle that here?
        return { skills: { "model.action" => model_class } }
      end

      {
         include: [BuildMethods],
            step: Build,
            name: "model.build",
          skills: { "model.class" => model_class, "model.action" => action },
        operator: :&,
      }
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
        model = model_class.find_by(id: params[:id])

        self["result.model"] = Result.new(!model.nil?, {})
        model
      end
    end
  end

  # calls operation.model!(params).
  Model::Build  = ->(input, options) { options["model"] = input.model!(options["params"]) }
end
