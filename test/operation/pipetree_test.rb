require "test_helper"

# self["pipetree"] = ::Pipetree[
#       Trailblazer::Operation::New,
#       # SetupParams,
#       Trailblazer::Operation::Model::Build,
#       Trailblazer::Operation::Model::Assign,
#       Trailblazer::Operation::Call,
#     ]



# def deserialize(*)
#     super
#     self.datetime = DateTime.parse("#{date} #{time}")
#   end

class PipetreeTest < Minitest::Spec
  Song = Struct.new(:title)

  class Create < Trailblazer::Operation
    include Builder
    include Pipetree # this will add the functions, again, unfortunately. definitely an error source.
  end

  it { Create["pipetree"].inspect.must_equal %{[>>Build,>>New,>>Call,Result::Build,>>New,>>Call,Result::Build]} }

  #---
  # playground
  require "trailblazer/operation/policy"
  require "trailblazer/operation/guard"

  class Edit < Trailblazer::Operation
    include Builder
    include Policy::Guard
    include Contract::Step
    contract do
      property :title
      validates :title, presence: true
    end


    MyValidate = ->(input, options) { res= input.validate(options["params"]) { |f| f.sync } }
    # we can have a separate persist step and wrap in transaction. where do we pass contract, though?
    step MyValidate, before: Call #replace: Contract::ValidLegacySwitch
    #
    MyAfterSave = ->(input, options) { input["after_save"] = true }
    success MyAfterSave, after: MyValidate

    ValidateFailureLogger = ->(input, options) { input["validate fail"] = true }
    failure ValidateFailureLogger, after: MyValidate

    success ->(input, options) { input.process(options["params"]) }, replace: Call, name: "my.params"

    include Model

    LogBreach = ->(input, options) { input.log_breach! }

    failure LogBreach, after: Policy::Evaluate

    model Song
    policy ->(*) { self["current_user"] }

    def log_breach!
      self["breach"] = true
    end

    def process(params)
      self["my.valid"] = true
    end

    self["pipetree"]._insert(Contract::ValidLegacySwitch, {delete: true}, nil, nil)
  end

  puts Edit["pipetree"].inspect(style: :rows)

  it { Edit["pipetree"].inspect.must_equal %{[>>operation.build,>>operation.new,&model.build,&policy.guard.evaluate,<LogBreach,>contract.build,&MyValidate,<ValidateFailureLogger,>MyAfterSave,>my.params["params"]]} }

  # valid case.
  it {
    # puts "valid"
  # puts Edit["pipetree"].inspect(style: :rows)
    result = Edit.({ title: "Stupid 7" }, "current_user" => true)
    # puts "success! #{result.inspect}"
    result["my.valid"].must_equal true
    result["breach"].must_equal nil
    result["after_save"].must_equal true
    result["validate fail"].must_equal nil
  }
  # beach! i mean breach!
  it {
    # puts "beach"
  # puts Edit["pipetree"].inspect(style: :rows)
    result = Edit.({})
    # puts "@@@@@ #{result.inspect}"
    result["my.valid"].must_equal nil
    result["breach"].must_equal true
    result["validate fail"].must_equal true
    result["after_save"].must_equal nil
  }
end

# TODO: show the execution path in pipetree
# unified result.contract, result.policy interface
