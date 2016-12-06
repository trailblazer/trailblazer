class Trailblazer::Operation
  module Persist
    def self.import!(operation, import, options={})
      save_method   = options[:method] || :save
      contract_name = options[:name] || "contract.default"

      import.(:&, ->(input, options) { options[contract_name].send(save_method) }, # TODO: test me.
        name: "persist.save")
    end
  end

  def self.Persist(*args, &block)
    [Persist, args, block]
  end
end
