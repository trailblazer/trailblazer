require "test_helper"
require "trailblazer/operation/policy"

class PolicyTest < Minitest::Spec
  Song = Struct.new(:id) do
    def self.find(id); new(id) end
  end

  class Auth
    def initialize(user, model); @user, @model = user, model end
    def only_user?; @user == Module && @model.nil? end
    def user_object?; @user == Object end
    def user_and_model?; @user == Module && @model.class == Song end
    def inspect; "<Auth: user:#{@user.inspect}, model:#{@model.inspect}>" end
  end

  #---
  # Instance-level: Only policy, no model
  class Create < Trailblazer::Operation
    self.| Policy[Auth, :only_user?]
    self.| Call

    def process(*)
      self["process"] = true
    end
  end

  # successful.
  it do
    result = Create.({}, "user.current" => Module)
    result["process"].must_equal true
    #- result object, policy
    result["result.policy"].success?.must_equal true
    result["result.policy"]["message"].must_equal nil
    # result[:valid].must_equal nil
    result["policy"].inspect.must_equal %{<Auth: user:Module, model:nil>}
  end
  # breach.
  it do
    result = Create.({}, "user.current" => nil)
    result["process"].must_equal nil
    #- result object, policy
    result["result.policy"].success?.must_equal false
    result["result.policy"]["message"].must_equal "Breach"
  end
  # inject different policy.
  it { Create.({}, "user.current" => Object, "policy.evaluator" => Trailblazer::Operation::Policy::Permission.new(Auth, :user_object?))["process"].must_equal true }
  it { Create.({}, "user.current" => Module, "policy.evaluator" => Trailblazer::Operation::Policy::Permission.new(Auth, :user_object?))["process"].must_equal nil }


  #---
  # inheritance, adding Model
  class Show < Create
    self.| Model[Song, :create]#, before: "policy.evaluate"
    puts "@@@@@ #{Show["pipetree"].inspect}"
  end

  # invalid because user AND model.
  it do
    result = Show.({}, "user.current" => Module)
    result["process"].must_equal nil
    result["model"].inspect.must_equal %{#<struct PolicyTest::Song id=nil>}
    # result["policy"].inspect.must_equal %{#<struct PolicyTest::Song id=nil>}
  end

  # valid because new policy.
  it do
    # puts Show["pipetree"].inspect
    result = Show.({}, "user.current" => Module, "policy.evaluator" => Trailblazer::Operation::Policy::Permission.new(Auth, :user_and_model?))
    result["process"].must_equal true
    result["model"].inspect.must_equal %{#<struct PolicyTest::Song id=nil>}
    result["policy"].inspect.must_equal %{<Auth: user:Module, model:#<struct PolicyTest::Song id=nil>>}
  end

  ##--
  # TOOOODOOO: Policy and Model before Build ("External" or almost Resolver)
  class Edit < Trailblazer::Operation
    self.| Model[Song, :update]
    self.| Policy[Auth, :user_and_model?]
    self.| Call

    def process(*); self["process"] = true end
  end

  # successful.
  it do
    result = Edit.({ id: 1 }, "user.current" => Module)
    result["process"].must_equal true
    result["model"].inspect.must_equal %{#<struct PolicyTest::Song id=1>}
    result["result.policy"].success?.must_equal true
    result["result.policy"]["message"].must_equal nil
    # result[:valid].must_equal nil
    result["policy"].inspect.must_equal %{<Auth: user:Module, model:#<struct PolicyTest::Song id=1>>}
  end

  # breach.
  it do
    result = Edit.({ id: 4 }, "user.current" => nil)
    result["model"].inspect.must_equal %{#<struct PolicyTest::Song id=4>}
    result["process"].must_equal nil
    result["result.policy"].success?.must_equal false
    result["result.policy"]["message"].must_equal "Breach"
  end
end
