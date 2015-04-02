module Trailblazer::Operation::Scope
  def self.included(base)
    # just require if some Operation uses it
    require 'ransack'
    attr_reader :search
  end

  def perform_search(params)
    search = @collection.ransack(params[:q])
    @collection = search.result
    search
  end
end
