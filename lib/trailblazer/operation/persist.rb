class Trailblazer::Operation
  module Contract
    module Persist
      def self.import!(operation, import, options={})
        save_method   = options[:method] || :save
        contract_name = options[:name] || "contract.default"

        import.(:&, ->(input, options) { options[contract_name].send(save_method) }, # TODO: test me.
          name: "persist.save")
      end
    end
  end

  DSL.macro!(:Persist, Contract::Persist, Contract.singleton_class) # Contract::Persist()
end
