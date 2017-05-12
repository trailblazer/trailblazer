class Trailblazer::Operation
  module Callable
    def self.import!(operation, import, callable, result:)
      import.(:&, ->(input, options) {
        call_result = callable._call(*options.to_runtime_data)
        options[result] = call_result['result']
        call_result.success?
      }, {})
    end
  end

  DSL.macro!(:Callable, Callable)
end
