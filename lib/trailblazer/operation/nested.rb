class Trailblazer::Operation
  module Nested
    # Please note that the instance_variable_get are here on purpose since the
    # superinternal API is not entirely decided, yet.
    def self.import!(operation, import, step)
      if step.is_a?(Class) && step <= Trailblazer::Operation # interestingly, with < we get a weird nil exception. bug in Ruby?
        proc = ->(input, options) { step._call(*options.to_runtime_data) }
      else
        proc = ->(input, options) { step.(options, input).(*options.to_runtime_data) }
      end

      import.(:&, ->(input, options) {
        result = proc.(input, options) # TODO: what about containers?

        result.instance_variable_get(:@data).to_mutable_data.each do |k,v|
          options[k] = v
        end

        result.success? # DISCUSS: what if we could simply return the result object here?
      }, {} )
    end
  end

  DSL.macro!(:Nested, Nested)
end

