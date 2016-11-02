require "test_helper"

module Inspect
  def inspect
    "<#{self.class.to_s.split("::").last} @model=#{@model}>"
  end
  alias_method :to_s, :inspect
end

class OperationRunTest < MiniTest::Spec
  class Operation < Trailblazer::Operation

    require "trailblazer/operation/contract"
    include Contract::Explicit

    # allow providing your own contract.
    self["contract.default.class"] = class MyContract
      def initialize(*)
      end
      def call(params)
        Mock::Result.new(params)
      end

      def errors
        Struct.new(:to_s).new("Op just calls #to_s on Errors!")
      end
      self
    end

    def process(params)
      model = Object
      validate(params, model: model)
    end

    include Inspect
  end


  describe "Raise" do
    class Follow < Trailblazer::Operation
      require "trailblazer/operation/raise"
      require "trailblazer/operation/contract"
      include Contract::Explicit
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
    it { Follow.(is_valid:true).success?.must_equal true }
  end
end


class OperationTest < MiniTest::Spec
  # #validate yields contract when valid
  class OperationWithValidateBlock < Trailblazer::Operation
    require "trailblazer/operation/contract"
    include Contract::Explicit
    self["contract.default.class"] = class Contract
      def initialize(*)
      end

      def call(params)
        Mock::Result.new(params)
      end

      attr_reader :errors
      self
    end

    def process(params)
      validate(params, model: Object.new) do |c|
        self["secret_contract"] = c.class
      end
    end
  end

  it { OperationWithValidateBlock.(false)["secret_contract"].must_equal nil }
  it { OperationWithValidateBlock.(true)["secret_contract"].to_s.must_equal "Mock::Result" }


  # test validate wit if/else
  class OperationWithValidateAndIf < Trailblazer::Operation
    require "trailblazer/operation/contract"
    include Contract::Explicit
    self["contract.default.class"] = class Contract
      def initialize(*)
      end

      def call(params)
        Mock::Result.new(params)
      end
      attr_reader :errors
      self
    end

    def process(params)
      if validate(params, model: Object.new)
        self["secret_contract"] = contract.class
      else
        self["secret_contract"] = "so wrong!"
      end
    end
  end

  it { OperationWithValidateAndIf.(false)["secret_contract"].must_equal "so wrong!" }
  it { OperationWithValidateAndIf.(true)["secret_contract"].must_equal OperationWithValidateAndIf::Contract }
end


class OperationErrorsTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    require "trailblazer/operation/contract"
    include Contract::Explicit
    contract do
      property :title, validates: { presence: true }
    end

    def process(params)
      validate(params, model: OpenStruct.new) {}
    end
  end

  it do
    result = Operation.({})
    result["errors.contract"].to_s.must_equal "{:title=>[\"can't be blank\"]}"
  end
end
