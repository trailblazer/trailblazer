require 'test_helper'
require 'trailblazer/operation/responder'

class ResponderTest < MiniTest::Spec
  Song = Struct.new(:id)

  class Operation < Trailblazer::Operation
    include CRUD
    model Song
    include Responder

    def process(params)
      invalid!(self) if params == false
      self
    end
  end

  # test ::model_name
  it { Operation.model_name.plural.must_equal "responder_test_songs" }

  # #errors
  it { Operation[true].errors.must_equal [] }
  it { Operation[false].errors.must_equal [1] } # TODO: since we don't want responder to render anything, just return _one_ error. :)

  # TODO: integration test with Controller.
end