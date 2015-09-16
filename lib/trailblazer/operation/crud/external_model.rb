require "trailblazer/operation/crud"

class Trailblazer::Operation
  module CRUD
    # Builds (finds or creates) the model _before_ the operation is instantiated.
    # Passes the model instance into the builder with the following signature.
    #
    #   builds ->(model, params)
    #
    # The initializer will now expect you to pass the model in via options[:model]. This
    # happens automatically when coming from a builder.
    module ExternalModel
      def self.included(includer)
        includer.extend CRUD::DSL
        includer.extend CRUD::BuildModel
        includer.extend ClassMethods
      end

      def assign_model!(*) # i don't like to "disable" the `@model =` like this but it's the simplest for now.
        @model = @options[:model]
      end


      module ClassMethods
      private
        def build_operation(params, options={}) # TODO: merge with Resolver::build_operation.
          model = model!(params)
          build_operation_class(model, params). # calls builds->(model, params).
            new(params, options.merge(model: model))
        end
      end
    end
  end
end