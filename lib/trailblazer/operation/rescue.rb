class Trailblazer::Operation
  def self.Rescue(*exceptions, handler: lambda { |*| }, &block)
    exceptions = [StandardError] unless exceptions.any?
    handler    = Trailblazer::Option(handler)

    # This block is evaluated by {Wrap} which currently expects a binary return type.
    rescue_block = ->(options, operation, *, &nested_activity) {
      begin
        nested_activity.call
      rescue *exceptions => exception
        handler.call(exception, options, exec_context: operation) # FIXME: when there's an error here, it shows the wrong exception!
        false
      end
    }

    Wrap(rescue_block, &block)
    # FIXME: name
    # [ step, name: "Rescue:#{block.source_location.last}" ]
  end
end

