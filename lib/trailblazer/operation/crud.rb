require "trailblazer/operation/crud/dsl"

module Trailblazer
  class Operation
    # The CRUD module will automatically create/find models for the configured +action+.
    # It adds a public  +Operation#model+ reader to access the model (after performing).
    module CRUD
      module Included
        def included(base)
          base.extend DSL
        end
      end
      # this makes ::included overrideable, e.g. to add more featues like CRUD::ActiveModel.
      extend Included


      # Methods to create the model according to class configuration and params.
      module ModelBuilder
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
      end


      # #validate no longer accepts a model since this module instantiates it for you.
      def validate(params, model=self.model, *args)
        super(params, model, *args)
      end

    private
      include ModelBuilder
      alias_method :find_model, :update_model

      def model_class
        self.class.model_class
      end
      def action_name
        self.class.action_name
      end


      # Rails-specific.
      # ActiveModel will automatically call Form::model when creating the contract and passes
      # the operation's +::model+, so you don't have to call it twice.
      # This assumes that the form class includes Form::ActiveModel, though.
      module ActiveModel
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def contract(&block)
            super
            contract_class.model(model_class) # this assumes that Form::ActiveModel is mixed in.
          end
        end
      end
    end
  end
end
