require 'test_helper'

require 'trailblazer/operation'
class OperationTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    def flow(params, &block)
      # block is "controller" block

      if params[:valid] # contract.validate()
        yield 1
      end
    end
  end

  it do
    @result = nil

    Operation.flow({:id => 1, :valid => true}) do |model| # usually, model _is_ the Contract/Form.
      @result = true # executed in real context.
    end
    # usually, you'd use return in the block?
    @result ||= false

    @result.must_equal true
  end
end



def update
  Operation::Update.flow(params) do |contract|
    @profile = contract.model
    return redirect_to ...
  end

  render :new # invalid
end


class Operation::Update
  def flow(params)
    girl = CoverGirl.new

    params = params[:cover_girl]
    params.merge!(
      image_fingerprint: Time.now.to_i,
    )

    super(girl, params, Contract) do |contract|
      res = contract.save

      # TODO: assert that save was successful. this could be another flowing contract?
      CoverGirl::Upload.new(girl).call(contract.image)
    end
end

class Operation::Update
  def flow(params)
    girl = CoverGirl.new

    girl.update_attributes(params)

    super(girl, params, Contract) do |contract|
    # validate(girl, params, Contract)
      res = contract.save

      # TODO: assert that save was successful. this could be another flowing contract?
      CoverGirl::Upload.new(girl).call(contract.image)
    end
end