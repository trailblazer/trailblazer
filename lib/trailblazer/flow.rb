module Trailblazer
  # Endpoint behaviour.
  module Flow
    module Flow
      def flow(params, operation=self)
        res, args = operation.run(params) # Operation::run, not Operation#run.

        if res
          yield args if block_given?
        end

        return args if block_given?
        [res, args]
      end
    end
    include Flow
    extend Flow
  end
end