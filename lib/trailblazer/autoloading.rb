Trailblazer::Operation.class_eval do
  autoload :Controller, "trailblazer/operation/controller"
  autoload :Responder,  "trailblazer/operation/responder"
  autoload :CRUD,       "trailblazer/operation/crud"
  autoload :Collection, "trailblazer/operation/collection"
end
