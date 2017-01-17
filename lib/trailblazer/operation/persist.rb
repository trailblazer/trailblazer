class Trailblazer::Operation
  module Contract
    def self.Persist(method: :save, name: "default")
      path = "contract.#{name}"
      step = ->(input, options) { options[path].send(method) }

      [ step, name: "persist.save" ]
    end
  end
end
