# Assigns an additional instance variable for +@model+ named after the model's table name (e.g. @comment).
module Trailblazer::Operation::Controller::ActiveRecord
private
  def setup_operation_instance_variables!(operation, options)
    super
    instance_variable_set(:"@#{operation_model_name}", @model)
  end

  def operation_model_name
    # set the right variable name if collection
    if @operation.is_a?(Trailblazer::Operation::Collection)
      return @model.model.table_name.split(".").last
    end
    @model.class.table_name.split(".").last.singularize
  end
end
