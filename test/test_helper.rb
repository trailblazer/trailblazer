require 'trailblazer'
require 'minitest/autorun'

# TODO: convert tests to non-rails.
require "reform/rails"
require "reform/form/active_model/validations"
Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end

require "trailblazer/operation/builder"
require "trailblazer/operation/model"
require "trailblazer/operation/contract"
require "trailblazer/operation/representer"

module Kernel
  alias __original_raise raise

  def raise(string, *args)
    __original_raise(string.inspect) if args == []
    __original_raise(string, *args)
  end
end
