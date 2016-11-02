require 'test_helper'
require "trailblazer/operation/callback"
require "trailblazer/operation/contract"

# callbacks are tested in Disposable::Callback::Group.
class OperationCallbackTest < MiniTest::Spec
  Song = Struct.new(:name)

  class Create < Trailblazer::Operation
    include Callback
    include Contract::Explicit

    contract do
      property :name
    end

    callback do
      on_change :notify_me!
      on_change :notify_you!
    end

    # TODO: always dispatch, pass params.

    def process(params)
      @model = Song.new

      validate(params, model: @model) do
        callback!
      end
    end

    def dispatched
      self["dispatched"] ||= []
    end

  private
    def notify_me!(*)
      dispatched << :notify_me!
    end

    def notify_you!(*)
      dispatched << :notify_you!
    end
  end


  class Update < Create
    # TODO: allow skipping groups.
    # skip_dispatch :notify_me!

    callback do
      remove! :on_change, :notify_me!
    end
  end


  it "invokes all callbacks" do
    res = Create.({"name"=>"Keep On Running"})
    res["dispatched"].must_equal [:notify_me!, :notify_you!]
  end

  it "does not invoke removed callbacks" do
    res = Update.({"name"=>"Keep On Running"})
    res["dispatched"].must_equal [:notify_you!]
  end
end
