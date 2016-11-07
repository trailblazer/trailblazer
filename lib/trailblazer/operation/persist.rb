class Trailblazer::Operation
  module Persist
    extend Stepable

    def self.import!(operation)
      operation["pipetree"].& ->(input, options) { options["contract"].save },
        name:   "persist.save",
        before: "operation.result"
    end
  end
end
