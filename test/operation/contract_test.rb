require "test_helper"


class OperationContractTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
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
    op = Operation.(title: "Beethoven")
    op.contract.id.must_equal 1
    op.contract.title.must_equal "Beethoven"
    op.contract.length.must_equal 3
  end
end

class OperationContractWithTwinOptionsTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    contract do
      property :id
      property :title, virtual: true
    end

    def process(params)
      model = Struct.new(:id).new

      contract(model, title: "Bad Feeling")

      validate(params)
    end
  end

  # allow using #contract to inject model and arguments.
  it do
    op = Operation.(id: 1)
    op.contract.id.must_equal 1
    op.contract.title.must_equal "Bad Feeling"
  end

  describe "#contract with Composition" do

  end
end

class OperationContractWithTwinOptionsAndContractClassTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
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
    op = Operation.(id: 1)
    op.contract.title.must_equal "Bad Feeling"
    op.contract.must_be_instance_of Operation::Contract
  end
end

class OperationContractWithDeprecatedArgumentsTest < MiniTest::Spec # TODO: remove in 1.3.
  class Operation < Trailblazer::Operation
    contract do
      property :id
      property :title, virtual: true
    end

    Contract = Class.new(contract_class)

    def process(params)
      model = Struct.new(:id).new

      contract(model, Contract) # use contract class where should be options now!

      validate(params)
    end
  end

  # allow using #contract to inject model and arguments.
  it do
    op = Operation.(id: 1)
    op.contract.id.must_equal 1
    op.contract.class.must_equal Operation::Contract
  end
end
