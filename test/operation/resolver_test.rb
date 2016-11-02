require "test_helper"
require "trailblazer/operation/resolver"

class BuilderTest < Minitest::Spec
  Song = Struct.new(:id) do
    def self.find(id); new(id) end
  end

  class Auth
    def initialize(*args); @user, @model = *args end
    def only_user?; @user == Module && @model.nil? end
    def user_object?; @user == Object end
    def user_and_model?; @user == Module && @model.class == Song end
    def inspect; "<Auth: user:#{@user.inspect}, model:#{@model.inspect}>" end
  end

  class A < Trailblazer::Operation
    include Builder
    builds ->(options) {
      return P if options["params"] == { some: "params", id:1 }
      return B if options["policy"].inspect == %{<Auth: user:Module, model:#<struct BuilderTest::Song id=3>>} # both user and model:id are set!
      return M if options["model"].inspect == %{#<struct BuilderTest::Song id=9>}
    }

    include Resolver
    model Song, :update
    policy Auth, :user_and_model?

    class P < self; end
    class B < self; end
    class M < self; end

    def process(*); self["x"] = self.class end
  end

  it { r=A.({ some: "params", id: 1 }, { "user.current" => Module })
    puts r.inspect

     }
  it { A.({ some: "params", id: 1 }, { "user.current" => Module })["x"].must_equal A::P }
  it { A.({                 id: 3 }, { "user.current" => Module })["x"].must_equal A::B }
  it { A.({                 id: 9 }, { "user.current" => Module })["x"].must_equal A::M }
end
