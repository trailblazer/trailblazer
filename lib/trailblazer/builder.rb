require "uber/builder"

module Trailblazer
  class Builder
    include Uber::Builder

    def self.call(*args)
      # first, call the builders. then, call on the result, the Operation instance.
      class_builder(self).(*args).(*args)
    end
  end
end
