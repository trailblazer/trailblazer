require "trailblazer/operation/crud/external_model"

class Trailblazer::Operation
  # Provides builds-> (model, policy, params).
  module Resolver
    def self.included(includer)
      includer.class_eval do
        include Policy # ::build_policy
        include CRUD::ExternalModel # ::build_operation_class

        extend BuildOperation # ::build_operation
      end
    end

    module BuildOperation
      def build_operation(params, options={})
        model  = model!(params)
        policy = policy_config.policy(params[:current_user], model)
        build_operation_class(model, policy, params).new(params, options.merge(model: model))
      end
    end
  end
end