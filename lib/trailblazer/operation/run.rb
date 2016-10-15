module Trailblazer
  # Backward-compatibility for 1.1.
  module Operation::Run
    def run(*args)
      result = call(*args)

      if block_given?
        yield result[:operation] if result[:valid]
        return result[:operation]
      end

      [result[:valid], result[:operation]]
    end
  end
end
