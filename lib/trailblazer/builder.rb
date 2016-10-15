require "uber/builder"

module Trailblazer
  module Builder
    def self.included(includer)
      includer.send :include, Uber::Builder
      includer.extend Call
    end

    module Call
      def call(*args)
        # first, call the builders. then, call on the result, the Operation instance.
        class_builder(self).(*args).(*args)
      end
    end
  end
end
