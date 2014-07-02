module Trailblazer
  class Operation
    def self.flow(params, &block)
      new.flow(params, &block)
    end

    def flow(params, &block)
      yield
    end
  end
end