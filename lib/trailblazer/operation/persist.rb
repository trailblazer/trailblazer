class Trailblazer::Operation
  module Contract
    def self.Persist(method: :save, name: "default")
      path = "contract.#{name}"
      step = ->(options, **) { options[path].send(method) }

      task = Railway::TaskBuilder.( step )

      [ task, { name: "persist.save" }, {} ]
    end
  end
end
