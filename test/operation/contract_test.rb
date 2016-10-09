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
      @inspect = "#{model} #{options.inspect}"
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
  it { Create.(contract_class: Form).must_equal "Object {}" }
  # contract(model, options)
  it { Create.(contract_class: Form, params:{options: true}).must_equal "Object {:admin=>true}" } # PARAMS; SUCKS
end
