class Trailblazer::Operation
  module Contract
    module Persist
      def self.import!(operation, import, method: :save, name: "default")
        path = "contract.#{name}"

        import.(:&, ->(input, options) { options[path].send(method) }, # TODO: test me.
          name: "persist.save")
      end
    end
  end

  DSL.macro!(:Persist, Contract::Persist, Contract.singleton_class) # Contract::Persist()
end
