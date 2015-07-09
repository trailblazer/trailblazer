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