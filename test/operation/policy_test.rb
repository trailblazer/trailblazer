require "test_helper"
require "trailblazer/operation/policy"

class OpPolicyTest < MiniTest::Spec
  Song = Struct.new(:name)

  class BlaOperation < Trailblazer::Operation
    include Policy

    def model!(*)
      Song.new
    end

    policy do |params|
      model.is_a?(Song) and params[:valid]
    end

    def process(*)
    end
  end

  # valid.
  it do
    op = BlaOperation.(valid: true)

  end

  # invalid.
  it do
    assert_raises Trailblazer::NotAuthorizedError do
      op = BlaOperation.(valid: false)
    end
  end
end