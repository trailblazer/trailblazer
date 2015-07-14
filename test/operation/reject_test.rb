require "test_helper"

class OperationRejectTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    def process(params)
      invalid! if params == false
    end
  end

  it do
    run = nil
    Operation.run(true) { run = true }
    run.must_equal true
  end

  it do
    run = nil
    Operation.run(false) { run = true }
    run.must_equal nil
  end

  it do
    run = nil
    op = Operation.reject(true) { run = true }
    run.must_equal nil
    op.must_be_instance_of Operation
  end

  it do
    run = nil
    Operation.reject(false) { run = true }
    run.must_equal true
  end
end