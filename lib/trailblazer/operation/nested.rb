module Trailblazer::Operation::Nested
  extend Trailblazer::Operation::Macro

  def self.import!(operation, import, step)
    import.(:>, ->(input, options) {
      result = step._call(*input.instance_variable_get(:@skills).to_runtime_data)
      result.instance_variable_get(:@data).to_mutable_data.each do |k,w|
        operation[k]=w
      end
    }, {} )
  end
end
