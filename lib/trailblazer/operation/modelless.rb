module Trailblazer
  class Operation
    module Modelless
      def model!(params)
        NullModel.new
      end

      class NullModel
        def method_missing(*)
        end
      end
    end
  end
end
