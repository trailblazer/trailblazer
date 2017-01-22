class Trailblazer::Operation
  def self.Nested(step)
    step = Nested.for(step)

    [ step, {} ]
  end

  module Nested
    # _call the nested `operation`.
    Call = ->(operation, options) { operation._call(*options.to_runtime_data) }

    def self.strut_for(step)
      if step.is_a?(Class) && step <= Trailblazer::Operation # interestingly, with < we get a weird nil exception. bug in Ruby?
        strut = ->(input, options) { Call.(step, options) }
      else
        option = Option::KW.(step)
        strut = ->(input, options) { Call.(option.(input, options), options) }
      end
    end

    # Please note that the instance_variable_get are here on purpose since the
    # superinternal API is not entirely decided, yet.
    def self.for(step)
      proc = strut_for(step)

      ->(input, options) do
        result = proc.(input, options) # TODO: what about containers?

        result.instance_variable_get(:@data).to_mutable_data.each { |k,v| options[k] = v }
        result.success? # DISCUSS: what if we could simply return the result object here?
      end
    end
  end
end

