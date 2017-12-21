module Trailblazer
  module Deprecation
    module Operation
      # This is super hacky. Fix you call calls everywhere (shouldn't take too long) and never load this file, again.
      module Call
        def self.options_for_call(params, *containers)
          if containers == []
            if params.is_a?(Hash) # this means we assume everything is cool. Create.( {...} )

            else # this means someone did Create.( #<WeirdParamsObject> )
              deprecate_positional_params(params, *containers)
              return { params: params }, *containers
            end
          else # Create.( params, "current_user" => ... )
            options, containers = containers[0], (containers[1..-1] || [])
            if options.is_a?(Hash) # old API
              warn "[Trailblazer] Please don't pass the `params` object as a positional argument into `Operation.()`, use the `:params` key and one hash for all: `Operation.( params: my_params, current_user: ... )` ."
              return options.merge( params: params ), *containers
            end
          end

          return params, *containers
        end

        def self.deprecate_positional_params(params, *containers)
          warn "[Trailblazer] Please don't pass the `params` object as a positional argument into `Operation.()`, use the `:params` key: `Operation.( params: my_params )` ."
        end
      end
    end
  end
end

Trailblazer::Operation.module_eval do
  # this sucks:
  def self.call(options={}, *containers)
    options, *containers = Trailblazer::Deprecation::Operation::Call.options_for_call(options, *containers)

    ctx = Trailblazer::Operation::PublicCall.options_for_public_call(options, *containers)

    # call the activity.
    last_signal, (options, flow_options) = __call__( [ctx, {}] ) # Railway::call # DISCUSS: this could be ::call_with_context.

    # Result is successful if the activity ended with an End event derived from Railway::End::Success.
    Trailblazer::Operation::Railway::Result(last_signal, options, flow_options)
  end
end
