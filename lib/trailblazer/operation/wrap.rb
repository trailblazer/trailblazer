class Trailblazer::Operation
  Base = self # TODO: we won't need this with 2.1.

  def self.Wrap(wrap, &block)
    operation = Class.new(Base)
    # DISCUSS: don't instance_exec when |pipe| given?
    operation.instance_exec(&block) # evaluate the nested pipe.

    pipe = operation["pipetree"]
    pipe.add(nil, nil, {delete: "operation.new"}) # TODO: make this a bit more elegant.

    step = Wrap.for(wrap, pipe)

    [ step, {} ]
  end

  module Wrap
    def self.for(wrap, pipe)
      ->(input, options) { wrap.(options, input, pipe, & ->{ pipe.(input, options) }) }
    end
  end # Wrap
end

# (options, *) => (options, operation, bla)
# (*, params:, **) => (options, operation, bla, options)
