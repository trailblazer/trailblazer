class Trailblazer::Operation
  module Rescue
    Noop = ->(*) {}

    def self.import!(_operation, import, *exceptions, handler: Noop, &block)
      exceptions = [StandardError] unless exceptions.any?
      handler    = Option.(handler)

      rescue_block = ->(options, operation, *, &nested_pipe) {
        begin
          res = nested_pipe.call
          res.first == ::Pipetree::Flow::Right # FIXME.
        rescue *exceptions => exception
          handler.call(operation, exception, options)
          false
        end
      }

      Wrap.import! _operation, import, rescue_block, name: "Rescue:#{block.source_location.last}", &block
    end
  end

  DSL.macro!(:Rescue, Rescue)
end

