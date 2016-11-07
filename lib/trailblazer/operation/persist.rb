class Trailblazer::Operation
  module Persist
    extend Stepable

    def self.import!(operation, import)
      import.(:&, ->(input, options) { options["contract"].save },
        name: "persist.save")
    end
  end
end
