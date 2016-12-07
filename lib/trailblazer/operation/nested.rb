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

  module Rescue
    def self.import!(_operation, import, *exceptions, handler:->(*){}, &block)
      exceptions = [StandardError] unless exceptions.any?
      handler    = Pipetree::DSL::Option.(handler)

      rescue_block = ->(options, operation, *, &nested_pipe) {
        begin
          res = nested_pipe.call
          res.first == ::Pipetree::Flow::Right # FIXME.
        rescue *exceptions => exception
          handler.call(operation, exception, options)
          #options["result.model.find"] = "argh! because #{exception.class}"
          false
        end
      }

      # operation.| operation.Wrap(rescue_block, &block), name: "Rescue:#{block.source_location.last}"
      Wrap.import! _operation, import, rescue_block, name: "Rescue:#{block.source_location.last}", &block
    end
  end

  DSL.macro!(:Rescue, Rescue)
end

