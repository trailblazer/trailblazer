class Trailblazer::Operation
  def self.Rescue(*exceptions, handler: lambda { |*| }, &block)
    exceptions = [StandardError] unless exceptions.any?
    handler    = Trailblazer::Option(handler)

    # This block is evaluated by {Wrap} which currently expects a binary return type.
    rescue_block = ->(options, operation, *, &nested_activity) {
      begin
        direction, options, flow_options = nested_activity.call

        # direction == Circuit::Right # FIXME. rewire this properly FIXME: do we want Circuit knowledge around here?
        direction.kind_of?(Railway::End::Success) # FIXME: redundant logic from Railway::call.
      rescue *exceptions => exception
        handler.call(exception, options, exec_context: operation) # FIXME: when there's an error here, it shows the wrong exception!
        false
      end
    }

    step, _ = Wrap(rescue_block, &block)

    [ step, name: "Rescue:#{block.source_location.last}" ]
  end
end

