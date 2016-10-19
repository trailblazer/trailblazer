require "trailblazer/operation/setup"

module Trailblazer
  class Operation
    # The Model module will automatically create/find models for the configured +action+.
    # It adds a public  +Operation#model+ reader to access the model (after performing).
    #
    # NOTE: this is deprecated with the emerge of trailblazer-pipetree.
    module Model
      def self.included(includer)
        includer.send :include, Setup # import #model! and friends.
        includer.extend DSL

        includer.extend Declarative::Heritage::Inherited
        includer.extend Declarative::Heritage::DSL

        require "trailblazer/operation/competences"
        includer.include Trailblazer::Operation::Competences
      end

      # Methods to create the model according to class configuration and params.
      module BuildModel
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
      end

      # #validate no longer accepts a model since this module instantiates it for you.
      def validate(params, model=self.model, *args)
        super(params, model, *args)
      end

    private
      include BuildModel


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
    end
  end
end
