Trailblazer.class_eval do
  autoload :NotAuthorizedError, "trailblazer/operation/policy"
end

Trailblazer::Operation.class_eval do
  autoload :Controller, "trailblazer/operation/controller"
  autoload :Model,      "trailblazer/operation/model"
  autoload :Collection, "trailblazer/operation/collection"
  autoload :Dispatch,   "trailblazer/operation/dispatch" # TODO: remove in 1.2.
  autoload :Callback,   "trailblazer/operation/callback"
  autoload :Module,     "trailblazer/operation/module"
  autoload :Representer,"trailblazer/operation/representer"
  autoload :Policy,     "trailblazer/operation/policy"
  autoload :Resolver,   "trailblazer/operation/resolver"
end
