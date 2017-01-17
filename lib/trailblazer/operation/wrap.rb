class Trailblazer::Operation
  module Wrap
    def self.import!(operation, import, wrap, _options={}, &block)
      pipe_api = API.new(operation, pipe = ::Pipetree::Railway.new)

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

      # add the step to the local pipe, but don't inherit.
      # goal is to let all that do the pipe, without any operation coupling.
      def add(track, strut_class, proc, options={})
        Pipetree::DSL.insert(@target, @pipe, track, strut_class, proc, options)
      end
    end
  end # Wrap

  DSL.macro!(:Wrap, Wrap)
end

# (options, *) => (options, operation, bla)
# (*, params:, **) => (options, operation, bla, options)
