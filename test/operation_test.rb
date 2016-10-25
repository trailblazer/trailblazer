require "test_helper"

module Inspect
  def inspect
    "<#{self.class.to_s.split("::").last} @model=#{@model}>"
  end
  alias_method :to_s, :inspect
end

class OperationParamsTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    def process(params)
      self.model = "#{params} and #{@params==params}"
    end

    def params!(params)
      { changed_params: params }
    end
  end

  # allows you returning new params in #params!.
  it { Operation.({valid: true}).model.to_s.must_equal "{:changed_params=>{:valid=>true}} and true" }
end

# Operation#model.
class OperationModelTest < MiniTest::Spec
  class Operation < Trailblazer::Operation

    def process(params)
    end

    def model!(params)
      params
    end
  end

  # #model.
  it { Operation.(Object).model.must_equal Object }
end

# Operation#model=.
class OperationModelWriterTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    def process(params)
      self.model = "#{params}"
    end
  end

  it { Operation.("I can set @model via a private setter").model.to_s.must_equal "I can set @model via a private setter" }
end

class OperationRunTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    require "trailblazer/operation/run"
    extend Run

    require "trailblazer/operation/contract"
    include Contract

    # allow providing your own contract.
    self["contract.default.class"] = class MyContract
      def initialize(*)
      end
      def validate(params)
        return true if params == "yes, true"
        false
      end

      def errors
        Struct.new(:to_s).new("Op just calls #to_s on Errors!")
      end
      self
    end

    def process(params)
      model = Object
      validate(params, model)
    end

    include Inspect
  end

  # contract is inferred from self::contract_class.
  # ::run returns result set when run without block.
  it { Operation.run("not true").to_s.must_equal %{[false, <Operation @model=>]} }
  it { Operation.run("yes, true").to_s.must_equal %{[true, <Operation @model=>]} }

  describe "Raise" do
    class Follow < Trailblazer::Operation
      require "trailblazer/operation/contract"
      include Contract
      contract do
      end

      module Validate
        def validate(is_valid)
          is_valid
        end
      end
      include Validate
      include Contract::Raise

      def process(params)
        validate(params[:is_valid])
      end
    end
    # #validate raises exception when invalid.
    it do
      exception = assert_raises(Trailblazer::Operation::InvalidContract) { Follow.(is_valid: false) }
      # exception.message.must_equal "Op just calls #to_s on Errors!"
    end
    it { Follow.(is_valid:true)[:valid].must_equal true }
  end

  # return operation when ::call
  it do
    Operation.("yes, true").to_s.must_equal %{<Operation @model=>}
    Operation.("yes, true")[:valid].must_equal true
  end


  # ::run with block returns operation.
  # valid executes block.
  it "block" do
    outcome = nil
    res = Operation.run("yes, true") do
      outcome = "true"
    end

    outcome.must_equal "true" # block was executed.
    res.to_s.must_equal %{<Operation @model=>}
  end

  # invalid doesn't execute block.
  it "block, invalid" do
    outcome = nil
    res = Operation.run("no, not true, false") do
      outcome = "true"
    end

    outcome.must_equal nil # block was _not_ executed.
    res.to_s.must_equal %{<Operation @model=>}
  end

  # block yields operation
  it do
    outcome = nil
    res = Operation.run("yes, true") do |op|
      outcome = op
    end

    outcome.to_s.must_equal %{<Operation @model=>} # block was executed.
    res.to_s.must_equal %{<Operation @model=>}
  end

  # # Operation#contract returns @contract
  it { Operation.("yes, true").contract.class.to_s.must_equal "OperationRunTest::Operation::MyContract" }




  describe "::present" do
    class NoContractOp < Trailblazer::Operation
      require "trailblazer/operation/contract"
      include Contract

      require "trailblazer/operation/present"
      extend Present

      def model!(*)
        Object
      end
    end

    # the operation and model are available, but no contract.
    it { NoContractOp.present({}).model.must_equal Object }
    # no contract is built.
    it { assert_raises(NoMethodError) { NoContractOp.present({}).contract } }
    it { assert_raises(NoMethodError) { NoContractOp.run({}) } }
  end
end


class OperationTest < MiniTest::Spec
  # test #invalid!
  class OperationWithoutValidateCall < Trailblazer::Operation
    require "trailblazer/operation/invalid"
    include Invalid

    def process(params)
      params || invalid!
    end

    include Inspect
  end

  # ::run
  it { OperationWithoutValidateCall.(true)[:valid].must_equal true }
  # invalid.
  it { OperationWithoutValidateCall.(false)[:valid].must_equal false }


  # #validate yields contract when valid
  class OperationWithValidateBlock < Trailblazer::Operation
    require "trailblazer/operation/contract"
    include Contract
    self["contract.default.class"] = class Contract
      def initialize(*)
      end

      def validate(params)
        params
      end

      attr_reader :errors
      self
    end

    def process(params)
      validate(params, Object.new) do |c|
        @secret_contract = c.class
      end
    end

    attr_reader :secret_contract
  end

  it { OperationWithValidateBlock.(false).secret_contract.must_equal nil }
  it { OperationWithValidateBlock.(true).secret_contract.must_equal OperationWithValidateBlock::Contract }


  # test validate wit if/else
  class OperationWithValidateAndIf < Trailblazer::Operation
    require "trailblazer/operation/contract"
    include Contract
    self["contract.default.class"] = class Contract
      def initialize(*)
      end

      def validate(params)
        params
      end
      attr_reader :errors
      self
    end

    def process(params)
      if validate(params, Object.new)
        @secret_contract = contract.class
      else
        @secret_contract = "so wrong!"
      end
    end

    attr_reader :secret_contract
  end

  it { OperationWithValidateAndIf.(false).secret_contract.must_equal "so wrong!" }
  it { OperationWithValidateAndIf.(true).secret_contract.must_equal OperationWithValidateAndIf::Contract }



  # ::present only runs #setup! which runs #model!.
  class ContractOnlyOperation < Trailblazer::Operation
    require "trailblazer/operation/contract"
    include Contract
    self["contract.default.class"] = class Contract
      def initialize(model, *)
        @_model = model
      end
      attr_reader :_model
      self
    end

    extend Present

    def model!(params)
      Object
    end

    def process(params)
      raise "This is not run!"
    end
  end

  it { ContractOnlyOperation.present({}).contract._model.must_equal Object }
end


class OperationErrorsTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    require "trailblazer/operation/contract"
    include Contract
    contract do
      property :title, validates: {presence: true}
    end

    def process(params)
      validate(params, OpenStruct.new) {}
    end
  end

  it do
    result = Operation.({})
    result[:errors].to_s.must_equal "{:title=>[\"can't be blank\"]}"
  end
end
