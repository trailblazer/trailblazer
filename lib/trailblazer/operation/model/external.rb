require "trailblazer/operation/model"

class Trailblazer::Operation
  module Model
    # Builds (finds or creates) the model _before_ the operation is instantiated.
    # Passes the model instance into the builder with the following signature.
    #
    #   builds ->(model, params)
    #
    # The initializer will now expect you to pass the model in via options[:model]. This
    # happens automatically when coming from a builder.
    module External
      def self.included(includer)
        includer.extend Declarative::Heritage::Inherited
        includer.extend Declarative::Heritage::DSL
        require "trailblazer/operation/competences"
        includer.include Trailblazer::Operation::Competences

        includer.extend Model::DSL
        includer.extend Model::BuildModel

        includer.extend Builder
        includer.extend ClassMethods
      end

      def assign_model!(*) # i don't like to "disable" the `@model =` like this but it's the simplest for now.
        #self["model"] = @options[:model]
      end


      module ClassMethods
        def build_operation(params, competences={}) # TODO: merge with Resolver::build_operation.
          model = model!(params)
          build_operation_class(model, params). # calls builds->(model, params).
            new(params, competences.merge(model: model))
        end
      end
    end
  end
end
