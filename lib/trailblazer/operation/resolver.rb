require "trailblazer/operation/policy"
require "trailblazer/operation/builder"

class Trailblazer::Operation
  # Provides builds-> (model, policy, params).
  module Resolver
    def self.included(includer)
      includer.class_eval do
        # include the DSL methods.
        include Policy # ::policy
        include Model  # ::model
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
  end
end
