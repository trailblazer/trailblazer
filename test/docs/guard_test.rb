require "test_helper"

#--
# with proc
class DocsGuardProcTest < Minitest::Spec
  #:proc
  class Create < Trailblazer::Operation
    step Policy::Guard( ->(options) { options["params"][:pass] } )
    step :process
    #~pipeonly

    def process(*)
      self["x"] = true
    end
    #~pipeonly end
  end
  #:proc end

  it { Create.(pass: false)["x"].must_equal nil }
  it { Create.(pass: true)["x"].must_equal true }

  #- result object, guard
  it { Create.(pass: true)["result.policy.default"].success?.must_equal true }
  it { Create.(pass: false)["result.policy.default"].success?.must_equal false }




   #---
  #- Guard inheritance
  class New < Create
    step Policy::Guard( ->(options) { options["current_user"] } ), override: true
  end

  it { New["pipetree"].inspect.must_equal %{[>operation.new,>policy.default.eval,>process]} }
end

#---
# with Callable
class DocsGuardTest < Minitest::Spec
  #:callable
  class MyGuard
    include Uber::Callable

    def call(options)
      options["params"][:pass]
    end
  end
  #:callable end

  #:callable-op
  class Create < Trailblazer::Operation
    step Policy::Guard( MyGuard.new )
    step :process
    #~pipe-only
    def process(*); self[:x] = true; end
    #~pipe-only end
  end
  #:callable-op end

  it { Create.(pass: false)[:x].must_equal nil }
  it { Create.(pass: true)[:x].must_equal true }
end

#---
# with method
# class DocsGuardMethodTest < Minitest::Spec
#   #:method
#   class Create < Trailblazer::Operation
#     step Policy::Guard[ : ]
#     step :process
#     #~pipe-only
#     def process(*); self[:x] = true; end
#     #~pipe-only end
#   end
#   #:method end

#   it { Create.(pass: false)[:x].must_equal nil }
#   it { Create.(pass: true)[:x].must_equal true }
# end

#---
# with name:
class DocsGuardNamedTest < Minitest::Spec
  #:name
  class Create < Trailblazer::Operation
    step Policy::Guard( ->(options) { options["current_user"] }, name: :user )
    # ...
  end
  #:name end

  it { Create.()["result.policy.user"].success?.must_equal false }
  it { Create.({}, "current_user" => Module)["result.policy.user"].success?.must_equal true }

  it {
  #:name-result
  result = Create.({}, "current_user" => true)
  result["result.policy.user"].success? #=> true
  #:name-result end
  }
end

#---
# class-level guard
class DocsGuardClassLevelTest < Minitest::Spec
  #:class-level
  class Create < Trailblazer::Operation
    step Policy::Guard( ->(options) { options["current_user"] == Module } ),
      before: "operation.new"
    #~pipe--only
    step ->(options) { options["x"] = true }
    #~pipe--only end
  end
  #:class-level end

  it { Create.(); Create["result.policy"].must_equal nil }
  it { Create.({}, "current_user" => Module)["x"].must_equal true }
  it { Create.({}                          )["x"].must_equal nil }
end

#---
# dependency injection
class DocsGuardInjectionTest < Minitest::Spec
  #:di-op
  class Create < Trailblazer::Operation
    step Policy::Guard( ->(options) { options["current_user"] == Module } )
  end
  #:di-op end

  it { Create.({}, "current_user" => Module).inspect("").must_equal %{<Result:true [nil] >} }
  it {
    result =
  #:di-call
  Create.({},
    "current_user"        => Module,
    "policy.default.eval" => Trailblazer::Operation::Policy::Guard.build(->(options) { false })
  )
  #:di-call end
    result.inspect("").must_equal %{<Result:false [nil] >} }
end


# TODO:
#policy.default
