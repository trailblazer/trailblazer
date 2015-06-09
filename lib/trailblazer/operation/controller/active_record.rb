# Assigns an additional instance variable for +@model+ named after the model's table name (e.g. @comment).
module Trailblazer::Operation::Controller::ActiveRecord
private
  def setup_operation_instance_variables!
    super
    instance_variable_set(:"@#{operation_model_name}", @model)
  end

  def operation_model_name
    @model.class.table_name.split(".").last.singularize
  end
end
