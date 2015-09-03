Trailblazer::Operation.class_eval do
  autoload :Controller, "trailblazer/operation/controller"
  autoload :Responder,  "trailblazer/operation/responder"
  autoload :CRUD,       "trailblazer/operation/crud"
  autoload :Collection, "trailblazer/operation/collection"
  autoload :Dispatch,   "trailblazer/operation/dispatch"
  autoload :Module,     "trailblazer/operation/module"
  autoload :Representer,"trailblazer/operation/representer"
  autoload :Policy,     "trailblazer/operation/policy"
  autoload :Resolver,     "trailblazer/operation/resolver"
end
