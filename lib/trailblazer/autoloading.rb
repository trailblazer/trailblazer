Trailblazer::Operation.class_eval do
  autoload :Controller, 'trailblazer/operation/controller'
  autoload :CRUD,       'trailblazer/operation/crud'
  autoload :Responder,  'trailblazer/operation/responder'
end
