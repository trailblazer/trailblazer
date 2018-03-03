class Trailblazer::Operation
  NoopHandler = lambda { |*| }

  def self.Rescue(*exceptions, handler: NoopHandler, &block)
    exceptions = [StandardError] unless exceptions.any?
    handler    = Trailblazer::Option(handler)

    # This block is evaluated by {Wrap} which currently expects a binary return type.
    rescue_block = ->((options, flow_options), **circuit_options, &nested_activity) {
      begin
        nested_activity.call
      rescue *exceptions => exception
        # DISCUSS: should we deprecate this signature and rather apply the Task API here?
        handler.call(exception, options, **circuit_options) # FIXME: when there's an error here, it shows the wrong exception!
        [ Trailblazer::Operation::Railway.fail!, [options, flow_options] ]
      end
    }

    Wrap(rescue_block, id: "Rescue(#{rand(100)})", &block)
    # FIXME: name
    # [ step, name: "Rescue:#{block.source_location.last}" ]
  end
end

