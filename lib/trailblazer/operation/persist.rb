class Trailblazer::Operation
  module Persist
    extend Macro

    def self.import!(operation, import, options={})
      save_method   = options[:method] || :save
      contract_name = options[:name] || "contract.default"

      import.(:&, ->(input, options) { options[contract_name].send(save_method) }, # TODO: test me.
        name: "persist.save")
    end
  end
end
