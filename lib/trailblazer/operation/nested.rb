module Trailblazer::Operation::Nested
  extend Trailblazer::Operation::Macro

  # Please note that the instance_variable_get are here on purpose since I don't
  # want to introduce readers that are used once.

  def self.import!(operation, import, step)
    import.(:>, ->(input, options) {
      result = step._call(*options.to_runtime_data)
      result.instance_variable_get(:@data).to_mutable_data.each do |k,w|
        operation[k] = w
      end
    }, {} )
  end
end
