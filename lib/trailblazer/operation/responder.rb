module Trailblazer::Operation::Responder
  # TODO: test me.
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def model_name
      model_class.model_name
    end
  end

  extend Forwardable
  def_delegators :@model, :to_param, :destroyed?, :persisted?

  def errors
    return [] if @valid
    [1]
  end

  def to_json(*)
    self.class.representer_class.new(model).to_json
  end

  def to_model
    @model
  end
end
