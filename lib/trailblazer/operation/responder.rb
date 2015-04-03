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
    unless self.model.nil?
      self.class.representer_class.new(model).to_json
    else
      self.collection.extend(self.class.representer_class.for_collection).to_json
    end
  end
end
