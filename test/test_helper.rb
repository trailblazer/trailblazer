require "trailblazer"
require "minitest/autorun"

# TODO: convert tests to non-rails.
require "reform"
require "reform/form/active_model/validations"
Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end

require "trailblazer/operation/callback"
require "trailblazer/operation/procedural/validate"

module Mock
  class Result
    def initialize(bool); @bool = bool end
    def success?; @bool end
    def errors; ["hihi"] end
  end
end

module Test
  module ReturnCall
    def self.included(includer)
      includer._insert :_insert, ReturnResult, {replace: Trailblazer::Operation::Result::Build}, ReturnResult, ""
    end
  end
  ReturnResult = ->(last, input, options) { input }
end
