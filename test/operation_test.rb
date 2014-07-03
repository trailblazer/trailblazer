require 'test_helper'

require 'trailblazer/operation'


class FlowTest < MiniTest::Spec
  class Operation
    def run(params)
      [params]
    end
  end

  it "no block" do
    res = Trailblazer::Flow.flow(true, Operation.new)
    res.must_equal [true]
  end

  it "no block, invalid" do
    res = Trailblazer::Flow.flow(false, Operation.new)
    res.must_equal [false]
  end

  it "block" do
    @outcome = "nil"
    res = Trailblazer::Flow.flow(true, Operation.new) do
      @outcome = "true"
    end
    @outcome ||= false # not executed.

    @outcome.must_equal "true" # block was executed.
    res.must_equal [true]
  end

  it "block, invalid" do
    res = Trailblazer::Flow.flow(false, Operation.new) do
      @outcome = "true"
    end
    @outcome ||= false # not executed.

    @outcome.must_equal false # block was _not_ executed.
    res.must_equal [false]
  end
end




class OperationTest < MiniTest::Spec
  class Contract #< Reform::Form
    def initialize(*)
    end
    def validate(params)
      params
    end
  end

  require 'ostruct'
  class Operation < Trailblazer::Operation
    extend Flow

    def run(params)
      model = OpenStruct.new
      validate(Contract, model, params)
    end
  end


  it "no block" do
    res = Operation.flow(true)
    res.must_equal [true, OpenStruct.new]
  end

  it "no block, invalid" do
    res = Operation.flow(false)
    res.must_equal [false, OpenStruct.new]
  end


  it do
   #@result = "nil"

    Trailblazer::Flow.flow(true, Operation)  do |model| # usually, model _is_ the Contract/Form.
      @result = true # executed in real context.
    end
    # usually, you'd use return in the block?
    @result ||= false

    @result.must_equal true
  end

  it do
    #@result = "nil"

    Trailblazer::Flow.flow(false, Operation) do |model| # usually, model _is_ the Contract/Form.
      @result = true # executed in real context.
    end
    # usually, you'd use return in the block?
    @result ||= false
    @result.must_equal false
  end
end


class SelfmadeOperationIncludingFlow < MiniTest::Spec
  class Operation
    extend Trailblazer::Flow # gives us Operation.flow.

    def self.run(params) # rename to #call
      new.run(params)
    end

    def run(params)
      [params] # done by validate
    end
  end

  it do
    Operation.flow(true).must_equal [true]
  end

  it "no block, invalid" do
    res = Operation.flow(false)
    res.must_equal [false]
  end

  it "block" do
    @outcome = "nil"
    res = Operation.flow(true) do
      @outcome = "true"
    end
    @outcome ||= false # not executed.

    @outcome.must_equal "true" # block was executed.
    res.must_equal [true]
  end

  it "block, invalid" do
    res = Operation.flow(false) do
      @outcome = "true"
    end
    @outcome ||= false # not executed.

    @outcome.must_equal false # block was _not_ executed.
    res.must_equal [false]
  end
end



# def update
#   Operation::Update.flow(params) do |contract|
#     @profile = contract.model
#     return redirect_to ...
#   end

#   render :new # invalid
# end


# class Operation::Create
#   def flow(params)
#     girl = CoverGirl.new

#     params = params[:cover_girl]
#     params.merge!(
#       image_fingerprint: Time.now.to_i,
#     )

#     super(girl, params, Contract) do |contract|
#       res = contract.save

#       # TODO: assert that save was successful. this could be another flowing contract?
#       CoverGirl::Upload.new(girl).call(contract.image)
#     end
#   end
# end

# class Operation::Update
#   def flow(params)
#     girl = CoverGirl.new

#     girl.update_attributes(params)

#     super(girl, params, Contract) do |contract|
#     # validate(girl, params, Contract)
#       res = contract.save

#       # TODO: assert that save was successful. this could be another flowing contract?
#       CoverGirl::Upload.new(girl).call(contract.image)
#     end
#   end
# end