require 'test_helper'

require 'trailblazer/operation'
class OperationTest < MiniTest::Spec
  class Contract #< Reform::Form
    def initialize(*)
    end
    def validate(params)
      params
    end
  end

  class Operation < Trailblazer::Operation
    def flow(params)
      validate(Contract, OpenStruct.new, params)
    end
  end

  it do
   #@result = "nil"

    Operation.flow(true) do |model| # usually, model _is_ the Contract/Form.
      @result = true # executed in real context.
    end
    # usually, you'd use return in the block?
    @result ||= false

    @result.must_equal true
  end

  it do
    #@result = "nil"

    Operation.flow(false) do |model| # usually, model _is_ the Contract/Form.
      @result = true # executed in real context.
    end
    # usually, you'd use return in the block?
    @result ||= false
    @result.must_equal false
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