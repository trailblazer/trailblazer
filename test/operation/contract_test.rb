require "test_helper"
require "trailblazer/operation/contract"

class ContractInjectTest < Minitest::Spec
  class Delete < Trailblazer::Operation
    include Contract
  end

  # inject contract instance via constructor.
  it { Delete.new(contract: "contract/instance").contract.must_equal "contract/instance" }
end

class ContractTest < Minitest::Spec
  class Form
    def initialize(model, options={})
      @inspect = "#{self.class}: #{model} #{options.inspect}"
    end

    def validate
      @inspect
    end
  end


  # contract(model).validate
  class Create < Trailblazer::Operation
    include Contract

    def call(options:false)
      return contract(Object, admin: true).validate if options
      contract(Object).validate
    end
  end

  # contract(model)
  it { Create.(contract_class: Form).must_equal "ContractTest::Form: Object {}" }
  # contract(model, options)
  it { Create.(contract_class: Form, params:{options: true}).must_equal "ContractTest::Form: Object {:admin=>true}" } # PARAMS; SUCKS

  # ::contract Form
  # contract(model).validate
  class Update < Trailblazer::Operation
    include Contract

    self.contract_class = Form

    def call(*)
      contract.validate
    end

    def model
      Object
    end
  end

  # use the class contract.
  it { Update.().must_equal "ContractTest::Form: Object {}" }
  # injected contract overrides class.
  it { Update.(contract_class: Injected = Class.new(Form)).must_equal "ContractTest::Injected: Object {}" }
end
