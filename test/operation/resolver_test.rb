# require "test_helper"

# class ResolverTest < Minitest::Spec
#   Song = Struct.new(:id) do
#     def self.find(id); new(id) end
#   end

#   class Auth
#     def initialize(*args); @user, @model = *args end
#     def only_user?; @user == Module && @model.nil? end
#     def user_object?; @user == Object end
#     def user_and_model?; @user == Module && @model.class == Song end
#     def inspect; "<Auth: user:#{@user.inspect}, model:#{@model.inspect}>" end
#   end

#   class A < Trailblazer::Operation
#     extend Builder::DSL
#     builds ->(options) {
#       return P if options["params"] == { some: "params", id:1 }
#       return B if options["policy.default"].inspect == %{<Auth: user:Module, model:#<struct ResolverTest::Song id=3>>} # both user and model:id are set!
#       return M if options["model"].inspect == %{#<struct ResolverTest::Song id=9>}
#     }

#     step Model( Song, :update ), before: "operation.new"
#     step Policy::Pundit( Auth, :user_and_model? ), before: "operation.new"
#     require "trailblazer/operation/resolver"
#     step Resolver(), before: "operation.new"

#     step :process

#     class P < self; end
#     class B < self; end
#     class M < self; end

#     def process(*); self["x"] = self.class end
#   end

#   it { A["pipetree"].inspect.must_equal %{[&model.build,&policy.default.eval,>>builder.call,>>operation.new,&process]} }

#   it { r=A.({ some: "params", id: 1 }, { "current_user" => Module })
#     puts r.inspect

#      }
#   it { A.({ some: "params", id: 1 }, { "current_user" => Module })["x"].must_equal A::P }
#   it { A.({                 id: 3 }, { "current_user" => Module })["x"].must_equal A::B }
#   it { A.({                 id: 9 }, { "current_user" => Module })["x"].must_equal A::M }
# end
