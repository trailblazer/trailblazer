class Trailblazer::Operation
  def self.Rescue(*exceptions, handler: lambda { |*| }, &block)
    exceptions = [StandardError] unless exceptions.any?
    handler    = Option.(handler)

    rescue_block = ->(options, operation, *, &nested_pipe) {
      begin
        res = nested_pipe.call
        res.first == ::Pipetree::Railway::Right # FIXME.
      rescue *exceptions => exception
        handler.call(operation, exception, options)
        false
      end
    }

    step, _ = Wrap(rescue_block, &block)

    [ step, name: "Rescue:#{block.source_location.last}" ]
  end
end

