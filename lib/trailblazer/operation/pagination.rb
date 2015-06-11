module Trailblazer::Operation::Pagination
  def self.included(base)
    # just require if some Operation uses it
    require 'kaminari'
    require 'kaminari/models/active_record_extension'
    ::ActiveRecord::Base.send :include, Kaminari::ActiveRecordExtension
  end
  
  def process_model!(params)
    @collection = @collection.page(params[:page]).per(params[:per_page])
    super
  end
end
