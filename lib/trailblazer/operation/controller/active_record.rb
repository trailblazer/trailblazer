module Trailblazer::Operation::Controller::ActiveRecord
  def setup_additional_instance_variables!
    instance_variable_set(:"@#{@model.class.table_name.singularize}", @model)
  end
end
