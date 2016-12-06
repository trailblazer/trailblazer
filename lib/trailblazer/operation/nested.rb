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

  module Wrap
    def self.import!(operation, import, wrap, _options={}, &block)
      pipe_api = API.new(operation, pipe = ::Pipetree::Flow[])

      # DISCUSS: don't instance_exec when |pipe| given?
      # yield pipe_api # create the nested pipe.
      pipe_api.instance_exec(&block) # create the nested pipe.

      import.(:&, ->(input, options) { wrap.(pipe, input, options) }, _options)
    end

    class API
      include Pipetree::DSL
      include Pipetree::DSL::Macros

      def initialize(target, pipe)
        @target, @pipe = target, pipe
      end

      def _insert(operator, proc, options={}) # TODO: test me.
        Pipetree::DSL.insert(@pipe, operator, proc, options, definer_name: @target.name)
      end

      def |(cfg, user_options={})
        Pipetree::DSL.import(@target, @pipe, cfg, user_options)
      end
      alias_method :step, :| # DISCUSS: uhm...
    end
  end # Wrap

  DSL.macro!(:Wrap, Wrap)

  module Rescue
    def self.import!(operation, import, *exceptions, &block)
      exceptions = [StandardError] unless exceptions.any?

      rescue_block = ->(pipe, operation, options) {
        begin
          res = pipe.(operation, options)
          res.first == ::Pipetree::Flow::Right # FIXME.
        rescue *exceptions
          #options["result.model.find"] = "argh! because #{exception.class}"
          false
        end
      }

      # operation.| operation.Wrap(rescue_block, &block), name: "Rescue:#{block.source_location.last}"
      Wrap.import! operation, import, rescue_block, name: "Rescue:#{block.source_location.last}", &block
    end
  end

  DSL.macro!(:Rescue, Rescue)
end

