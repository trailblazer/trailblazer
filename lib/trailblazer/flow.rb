module Trailblazer
  # Endpoint behaviour.
  module Flow
    module Flow
      def flow(params, operation=self)
        res, model = operation.run(params) # Operation::run, not Operation#run.

        if res
          yield model if block_given?
        end

        return model if block_given?
        [res, model]
      end
    end
    include Flow
    extend Flow
  end
end