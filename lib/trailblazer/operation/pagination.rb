module Trailblazer::Operation::Pagination
  def self.included(base)
    # just require if some Operation uses it
    require 'kaminari'
    require 'kaminari/models/active_record_extension'
    ::ActiveRecord::Base.send :include, Kaminari::ActiveRecordExtension
  end
  
  def perform_pagination(params)
    @collection.page(params[:page]).per(params[:per_page])
  end
end
