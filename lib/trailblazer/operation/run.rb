module Trailblazer
  # Backward-compatibility for 1.1.
  module Operation::Run
    def run(*args)
      result = call(*args)

      if block_given?
        yield result if result[:valid]
        return result
      end

      [result[:valid], result]
    end
  end
end
