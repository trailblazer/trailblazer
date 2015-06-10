require 'test_helper'

class OperationCallbackTest < MiniTest::Spec
  class Create < Trailblazer::Operation
    include Dispatch

    def process(params)
      dispatch :notify_me!
      dispatch :notify_you!, params

      # TODO:
      # dispatch :notify_whoever, Callable
      # dispatch :notify_whoever, lambda { |args| block }
      self
    end

    def dispatched
      @dispatched ||= []
    end

  private
    def notify_me!
      dispatched << :notify_me!
    end

    def notify_you!(params)
      dispatched << :notify_you!
    end
  end


  class Update < Create
    skip_dispatch :notify_me!
  end


  it "invokes all callbacks" do
    op = Create.({})
    op.dispatched.must_equal [:notify_me!, :notify_you!]
  end

  it "does not invoke skipped callbacks" do
    op = Update.({})
    op.dispatched.must_equal [:notify_you!]
  end
end