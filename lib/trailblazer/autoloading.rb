Trailblazer::Operation.class_eval do
  autoload :Controller, 'trailblazer/operation/controller'
  autoload :CRUD,       'trailblazer/operation/crud'
  autoload :Pagination, 'trailblazer/operation/pagination'
  autoload :Responder,  'trailblazer/operation/responder'
  autoload :Scope,      'trailblazer/operation/scope'
end
