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
  end
end
