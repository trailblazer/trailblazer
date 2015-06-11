module Trailblazer::Operation::Scope
  def self.included(base)
    # just require if some Operation uses it
    require 'ransack'
    attr_reader :search
  end

  def process_model!(params)
    @search = @collection.ransack(params[:q])
    @collection = @search.result
    super
  end
end
