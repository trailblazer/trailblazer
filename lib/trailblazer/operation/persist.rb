class Trailblazer::Operation
  module Persist
    extend Stepable

    def self.import!(operation, import, options={})
      save_method = options[:method] || :save

      import.(:&, ->(input, options) { options["contract.default"].send(save_method) }, # TODO: test me.
        name: "persist.save")
    end
  end
end
