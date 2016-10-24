require "trailblazer/operation/policy"
require "trailblazer/operation/builder"

class Trailblazer::Operation
  # Provides builds-> (model, policy, params).
  module Resolver
    def self.included(includer)
      includer.class_eval do
        extend Model::DSL  # ::model
        extend Policy::DSL # ::policy
      end

      includer.| Model::Build, after: Skill::Build
      includer.| Model::Assign, after: Model::Build
      includer.| Policy::Evaluate, after: Model::Assign
      includer.| Policy::Assign, after: Policy::Evaluate
    end
  end
end
