class Trailblazer::Operation
  module Wrap
    def self.import!(operation, import, wrap, _options={}, &block)
      pipe_api = API.new(operation, pipe = ::Pipetree::Flow[])

      # DISCUSS: don't instance_exec when |pipe| given?
      # yield pipe_api # create the nested pipe.
      pipe_api.instance_exec(&block) # evaluate the nested pipe. this gets written onto `pipe`.

      import.(:&, ->(input, options) { wrap.(options, input, pipe, & ->{ pipe.(input, options) }) }, _options)
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
end


# (options, *) => (options, operation, bla)
# (*, params:, **) => (options, operation, bla, options)
