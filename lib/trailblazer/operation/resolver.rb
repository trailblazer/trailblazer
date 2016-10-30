require "trailblazer/operation/policy"
require "trailblazer/operation/builder"

class Trailblazer::Operation
  # Provides builds-> (model, policy, params).
  module Resolver
    def self.included(includer)
      includer.class_eval do
        extend Model::DSL  # ::model
        extend Model::BuildMethods  # ::model!
        extend Policy::DSL # ::policy
      end

      includer.> Model::Build, prepend: true
      includer.& Policy::Evaluate, after: Model::Build
    end
  end
end
