require "trailblazer/operation/model/dsl"

module Trailblazer
  class Operation
    # The Model module will automatically create/find models for the configured +action+.
    # It adds a public  +Operation#model+ reader to access the model (after performing).
    module Model
      def self.included(base)
        base.extend DSL
      end

      # Methods to create the model according to class configuration and params.
      module BuildModel
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
      end


      # #validate no longer accepts a model since this module instantiates it for you.
      def validate(params, model=self.model, *args)
        super(params, model, *args)
      end

    private
      include BuildModel

      def model_class
        self.class.model_class
      end
      def action_name
        self.class.action_name
      end
    end
  end
end
