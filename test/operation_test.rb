require 'test_helper'

require 'trailblazer/operation'

module Comparable
  # only used for test.
  def ==(b)
    self.class == b.class
  end
end


class OperationRunTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    class Contract #< Reform::Form
      def initialize(*)
      end
      def validate(params)
        return false if params == false # used in ::[] with exception test.
        "local #{params}"
      end

      def errors
        Struct.new(:to_s).new("Op just calls #to_s on Errors!")
      end

      include Comparable
    end

    def process(params)
      model = Object
      validate(params, model)
    end
  end

  let (:operation) { Operation.new.extend(Comparable) }

  # contract is inferred from self::Contract.
  it { Operation.run(true).must_equal ["local true", operation] }

  # return operation, only, when ::call
  it { Operation.call(true).must_equal operation }
  it { Operation[true].must_equal operation }

  # ::[] raises exception when invalid.
  it do
    exception = assert_raises(Trailblazer::Operation::InvalidContract) { Operation[false] }
    exception.message.must_equal "Op just calls #to_s on Errors!"
  end

  # ::run without block returns result set.
  it { Operation.run(true).must_equal  ["local true", operation] }
  it { Operation.run(false).must_equal [false, operation] }

  # ::run with block returns operation.
  # valid executes block.
  it "block" do
    outcome = nil
    res = Operation.run(true) do
      outcome = "true"
    end
    # @outcome ||= false # not executed.

    outcome.must_equal "true" # block was executed.
    res.must_equal operation
  end

  # invalid doesn't execute block.
  it "block, invalid" do
    outcome = nil
    res = Operation.run(false) do
      outcome = "true"
    end

    outcome.must_equal nil # block was _not_ executed.
    res.must_equal operation
  end

  # TODO: this goes into Operation::Model
  # Operation#model returns @model.
  # it { Operation[true].model.must_equal }

  # Operation#contract returns @contract
  let (:contract)  { Operation::Contract.new }
  it { Operation[true].contract.must_equal contract }
end


class OperationTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    def process(params)
      validate(Object, params)
    end
  end

  # contract is inferred from self::Contract.
  it { assert_raises(NameError) { Operation.run(true) } }

  # no #process method defined.
  # DISCUSS: not sure if we need that.
  # class OperationWithoutProcessMethod < Trailblazer::Operation
  # end

  # it { OperationWithoutProcessMethod[{}].must_be_kind_of OperationWithoutProcessMethod }

  # #process and no validate.
  class OperationWithoutValidateCall < Trailblazer::Operation
    def process(params)
      params || invalid!(params)
    end
  end

  # ::run
  it { OperationWithoutValidateCall.run(Object).must_equal [true, Object] }
  # ::[]
  it { OperationWithoutValidateCall[Object].must_equal(Object) }
  # ::run with invalid!
  it { OperationWithoutValidateCall.run(nil).must_equal [false, nil] }
  # ::run with block, invalid
  it do
    OperationWithoutValidateCall.run(false) { @outcome = "true" }.must_equal false
    @outcome.must_equal nil
  end
  # ::run with block, valid
  it do
    OperationWithoutValidateCall.run(true) { @outcome = "true" }.must_equal true
    @outcome.must_equal "true"
  end

  # #validate yields contract when valid
  class OperationWithValidateBlock < Trailblazer::Operation
    class Contract
      def initialize(*)
      end

      def validate(params)
        params
      end
    end

    def process(params)
      validate(params, Object.new) do |c|
        @secret_contract = c
      end
    end

    attr_reader :secret_contract
  end

  it { OperationWithValidateBlock.run(false).last.secret_contract.must_equal nil }
  it { OperationWithValidateBlock[true].secret_contract.must_equal OperationWithValidateBlock::Contract.new.extend(Comparable) }

  # manually setting @valid
  class OperationWithManualValid < Trailblazer::Operation
    def process(params)
      @valid = false
      params
    end
  end

  # ::run
  it { OperationWithManualValid.run(Object).must_equal [false, Object] }
  # ::[]
  it { OperationWithManualValid[Object].must_equal(Object) }


  # re-assign params
  class OperationReassigningParams < Trailblazer::Operation
    def process(params)
      params = params[:title]
      params
    end
  end

  # ::run
  it { OperationReassigningParams.run({:title => "Day Like This"}).must_equal [true, "Day Like This"] }


  # #invalid!
  class OperationCallingInvalid < Trailblazer::Operation
    def process(params)
      return 1 if params
      invalid!(2)
    end
  end

  it { OperationCallingInvalid.run(true).must_equal [true, 1] }
  it { OperationCallingInvalid.run(nil).must_equal [false, 2] }


  # calling return from #validate block leaves result true.
  class OperationUsingReturnInValidate < Trailblazer::Operation
    class Contract
      def initialize(*)
      end
      def validate(params)
        params
      end
    end

    def process(params)
      validate(params, Object) do
        return 1
      end
      2
    end
  end

  it { OperationUsingReturnInValidate.run(true).must_equal [true, 1] }
  it { OperationUsingReturnInValidate.run(false).must_equal [false, 2] }


  # unlimited arguments for ::run and friends.
  class OperationReceivingLottaArguments < Trailblazer::Operation
    def process(model, params)
      [model, params]
    end
  end

  it { OperationReceivingLottaArguments.run(Object, {}).must_equal([true, [Object, {}]]) }


  # TODO: experimental.
  # ::contract to avoid running #validate.
  class ContractOnlyOperation < Trailblazer::Operation
    class Contract
      def initialize(model)
        @_model = model
      end
      attr_reader :_model
    end

    def process(params)
      @object = Object # arbitraty init code.

      validate(params, Object) do
        raise "this should not be run."
      end
    end
  end

  it { ContractOnlyOperation.contract({})._model.must_equal Object }

end

class OperationBuilderTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    def process(params)
      "operation"
    end

    class Sub < self
      def process(params)
        "sub:operation"
      end
    end

    builds do |params|
      Sub if params[:sub]
    end
  end

  it { Operation.run({}).last.must_equal "operation" }
  it { Operation.run({sub: true}).last.must_equal "sub:operation" }

  it { Operation[{}].must_equal "operation" }
  it { Operation[{sub: true}].must_equal "sub:operation" }
end
