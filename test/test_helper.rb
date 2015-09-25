require 'trailblazer'
require 'minitest/autorun'

require "reform/form/active_model/validations"
Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end