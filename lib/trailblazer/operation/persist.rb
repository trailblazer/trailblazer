class Trailblazer::Operation
  module Persist
    extend Stepable

    def self.import!(operation, pipe)
      pipe.(:&, ->(input, options) { options["contract"].save },
        name: "persist.save")
    end
  end
end
