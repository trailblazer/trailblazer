module Trailblazer::Operation::Nested
  extend Trailblazer::Operation::Macro

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

class Trailblazer::Operation
  module Wrap
    def self.import!(operation, import, wrap, &block)
      pipe_api = API.new(operation, pipe = ::Pipetree::Flow[])

      yield pipe_api # create the nested pipe.

      import.(:&, ->(input, options) { wrap.(pipe, input, options) }, {})
    end

    class API
      include Pipetree::DSL

      def initialize(target, pipe)
        @target, @pipe = target, pipe
      end

      def _insert(operator, proc, options={})
        Pipetree::DSL.insert(@pipetree, operator, proc, options, definer_name: @target.name)
      end

      def |(cfg, user_options={})
        Pipetree::DSL.import(@target, @pipe, cfg, user_options)
      end
    end
  end

  # DISCUSS: this is prototyping!
  def self.Wrap(*args, &block)
    [Wrap, *args, block]
    # extend Macro

    # def self.import!(operation, import, wrap, &block)
    # end
  end
end

