module Trailblazer
  module Test
    module Run
      # DISCUSS: use Endpoint here?
      # DISCUSS: use Controller code here?
      module_function
      def run(operation_class, *args)
        result = operation_class.(*args)

        raise "[Trailblazer] #{operation_class} wasn't run successfully. #{result.inspect}" if result.failure?

        result

      end
    end
  end
end
