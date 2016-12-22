class Trailblazer::Operation
  module Nested
    # Please note that the instance_variable_get are here on purpose since the
    # superinternal API is not entirely decided, yet.
    def self.import!(operation, import, step)
      import.(:&, ->(input, options) {
        result = step._call(*options.to_runtime_data)

        result.instance_variable_get(:@data).to_mutable_data.each do |k,v|
          options[k] = v
        end

        result.success? # DISCUSS: what if we could simply return the result object here?
      }, {} )
    end
  end

  DSL.macro!(:Nested, Nested)
end

