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
        policy = policy_config.call(params[:current_user], model)
        build_operation_class(model, policy, params).
          new(params, options.merge(model: model, policy: policy))
      end
    end

    def initialize(params, options)
      @policy = options[:policy]
      super
    end
  end
end