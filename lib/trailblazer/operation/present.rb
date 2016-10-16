module Trailblazer
  # Backward-compatibility for 1.1.
  module Operation::Present
    def present(*args)
      build_operation(*args)
    end
  end
end
