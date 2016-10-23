require "trailblazer/operation/model/external"
require "trailblazer/operation/policy"

class Trailblazer::Operation
  # Provides builds-> (model, policy, params).
  module Resolver
    def self.included(includer)
      includer.class_eval do
        include Policy # ::build_policy
        include Model::External # ::build_operation_class

        extend BuildOperation # ::build_operation
      end
    end

    module BuildOperation
      def build_operation(params, options={})
        model  = model!(params)
        policy = self["policy.evaluator"].call(params[:current_user], model)

        options["model"] = model
        options["policy"] = policy


        build_operation_class(model, policy, params).
          new(params, options)
      end
    end

    def initialize(params, options={})
      super
      self["policy"] = options["policy"]
    end
  end
end
