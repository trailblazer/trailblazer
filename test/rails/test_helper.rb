require 'trailblazer'
require 'minitest/autorun'

require "reform/form/active_model/validations"
Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end

require 'fake_app/rails_app.rb'
