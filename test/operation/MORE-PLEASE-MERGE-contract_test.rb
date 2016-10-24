require "test_helper"

class OperationContractMERGEMETest < Minitest::Spec
  class Operation < Trailblazer::Operation
    include Contract
    attr_reader :model

    contract do
      property :id
      property :title
      property :length
    end

    def process(params)
      @model = Struct.new(:id, :title, :length).new

      contract.id = 1
      validate(params) do
        contract.length = 3
      end
    end
  end

  # allow using #contract before #validate.
  it do
    contract = Operation.(title: "Beethoven")["contract"]
    contract.id.must_equal 1
    contract.title.must_equal "Beethoven"
    contract.length.must_equal 3
  end
end



class OperationContractWithTwinOptionsAndContractClassTest < Minitest::Spec
  class Operation < Trailblazer::Operation
    include Contract

    class Contract < Reform::Form
      property :title, virtual: true
    end

    def process(params)
      contract(Object.new, { title: "Bad Feeling" }, Contract)

      validate(params)
    end
  end

  # allow using #contract to inject model, options and class.
  it do
    contract = Operation.(id: 1)["contract"]
    contract.title.must_equal "Bad Feeling"
    contract.must_be_instance_of Operation::Contract
  end
end
