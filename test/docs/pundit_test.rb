require "test_helper"

#:policy
class MyPolicy
  def initialize(user, model)
    @user, @model = user, model
  end

  def create?
    @user == Module && @model.id.nil?
  end
end
#:policy end

#--
# with policy
class DocsPunditProcTest < Minitest::Spec
  Song = Struct.new(:id)

  #:pundit
  class Create < Trailblazer::Operation
    step Model( Song, :new )
    step Policy::Pundit( MyPolicy, :create? )
    # ...
  end
  #:pundit end

  it { Create.({}, "current_user" => Module).inspect("model").must_equal %{<Result:true [#<struct DocsPunditProcTest::Song id=nil>] >} }
  it { Create.({}                          ).inspect("model").must_equal %{<Result:false [#<struct DocsPunditProcTest::Song id=nil>] >} }

  it do
  #:pundit-result
  result = Create.({}, "current_user" => Module)
  result["result.policy.default"].success? #=> true
  result["result.policy.default"]["policy"] #=> #<MyPolicy ...>
  #:pundit-result end
    result["result.policy.default"].success?.must_equal true
    result["result.policy.default"]["policy"].is_a?(MyPolicy).must_equal true
  end

   #---
  #- Guard inheritance
  class New < Create
  end

  it { New["pipetree"].inspect.must_equal %{[>>operation.new,&model.build,&policy.default.eval]} }

  #---
  # dependency injection
  class AnotherPolicy < MyPolicy
    def create?
      true
    end
  end

  it {
    result =
  #:di-call
  Create.({},
    "current_user"        => Module,
    "policy.default.eval" => Trailblazer::Operation::Policy::Pundit.build(AnotherPolicy, :create?)
  )
  #:di-call end
    result.inspect("").must_equal %{<Result:true [nil] >} }
end

#-
# with name:
class PunditWithNameTest < Minitest::Spec
  Song = Struct.new(:id)

  #:name
  class Create < Trailblazer::Operation
    step Model( Song, :new )
    step Policy::Pundit( MyPolicy, :create?, name: "after_model" )
    # ...
  end
  #:name end

  it {
  #:name-call
  result = Create.({}, "current_user" => Module)
  result["result.policy.after_model"].success? #=> true
  #:name-call end
    result["result.policy.after_model"].success?.must_equal true }
end

#---
# class-level guard
# class DocsGuardClassLevelTest < Minitest::Spec
#   #:class-level
#   class Create < Trailblazer::Operation
#     step Policy::Guard[ ->(options) { options["current_user"] == Module } ],
#       before: "operation.new"
#     #~pipe--only
#     step ->(options) { options["x"] = true }
#     #~pipe--only end
#   end
#   #:class-level end

#   it { Create.(); Create["result.policy"].must_equal nil }
#   it { Create.({}, "current_user" => Module)["x"].must_equal true }
#   it { Create.({}                          )["x"].must_equal nil }
# end



# TODO:
#policy.default
