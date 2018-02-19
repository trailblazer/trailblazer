require "test_helper"

  #:policy
  class MyPolicy
    def initialize(user, model)
      @user, @model = user, model
    end

    def create?
      @user == Module && @model.id.nil?
    end

    def new?
      @user == Class
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

  it { Trailblazer::Operation::Inspect.(Create).must_equal %{[>model.build,>policy.default.eval]} }
  it { Create.(params: {}, current_user: Module).inspect(:model).must_equal %{<Result:true [#<struct DocsPunditProcTest::Song id=nil>] >} }
  it { Create.(params: {}                          ).inspect(:model).must_equal %{<Result:false [#<struct DocsPunditProcTest::Song id=nil>] >} }

  it do
  #:pundit-result
  result = Create.(params: {}, current_user: Module)
  result["result.policy.default"].success? #=> true
  result["result.policy.default"]["policy"] #=> #<MyPolicy ...>
  #:pundit-result end
    result["result.policy.default"].success?.must_equal true
    result["result.policy.default"]["policy"].is_a?(MyPolicy).must_equal true
  end

  #---
  #- override
  class New < Create
    step Policy::Pundit( MyPolicy, :new? ), override: true
  end

  it { Trailblazer::Operation::Inspect.(New).must_equal %{[>model.build,>policy.default.eval]} }
  it { New.(params: {}, current_user: Class ).inspect(:model).must_equal %{<Result:true [#<struct DocsPunditProcTest::Song id=nil>] >} }
  it { New.(params: {}, current_user: nil ).inspect(:model).must_equal %{<Result:false [#<struct DocsPunditProcTest::Song id=nil>] >} }

  #---
  #- override with :name
  class Edit < Trailblazer::Operation
    step Policy::Pundit( MyPolicy, :create?, name: "first" )
    step Policy::Pundit( MyPolicy, :new?,    name: "second" )
  end

  class Update < Edit
    step Policy::Pundit( MyPolicy, :new?, name: "first" ), override: true
  end

  it { Trailblazer::Operation::Inspect.(Edit).must_equal %{[>policy.first.eval,>policy.second.eval]} }
  it { Edit.(params: {}, current_user: Class).inspect(:model).must_equal %{<Result:false [nil] >} }
  it { Trailblazer::Operation::Inspect.(Update).must_equal %{[>policy.first.eval,>policy.second.eval]} }
  it { Update.(params: {}, current_user: Class).inspect(:model).must_equal %{<Result:true [nil] >} }

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
  Create.(params: {},
    current_user:            Module,
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
  result = Create.(params: {}, current_user: Module)
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

#   it { Create.(); Create["result.policy"].must_be_nil }
#   it { Create.(params: {}, current_user: Module)["x"].must_equal true }
#   it { Create.(params: {}                          )["x"].must_be_nil }
# end



# TODO:
#policy.default
