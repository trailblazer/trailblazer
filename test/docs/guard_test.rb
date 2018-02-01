require "test_helper"

#--
# with proc
class DocsGuardProcTest < Minitest::Spec
  #:proc
  class Create < Trailblazer::Operation
    step Policy::Guard( ->(options, pass:, **) { pass } )
    #~pipeonly
    step :process

    def process(options, **)
      options["x"] = true
    end
    #~pipeonly end
  end
  #:proc end

  it { Create.(pass: false)["x"].must_be_nil }
  it { Create.(pass: true)["x"].must_equal true }

  #- result object, guard
  it { Create.(pass: true)["result.policy.default"].success?.must_equal true }
  it { Create.(pass: false)["result.policy.default"].success?.must_equal false }

  #---
  #- Guard inheritance
  class New < Create
    step Policy::Guard( ->(options, current_user:, **) { current_user } ), override: true
  end

  it { Trailblazer::Operation::Inspect.(New).must_equal %{[>policy.default.eval,>process]} }
end

#---
# with Callable
class DocsGuardTest < Minitest::Spec
  #:callable
  class MyGuard
    include Uber::Callable

    def call(options, pass:, **)
      pass
    end
  end
  #:callable end

  #:callable-op
  class Create < Trailblazer::Operation
    step Policy::Guard( MyGuard.new )
    #~pipe-only
    step :process

    def process(options, **)
      options[:x] = true
    end
    #~pipe-only end
  end
  #:callable-op end

  it { Create.(pass: false)[:x].must_be_nil }
  it { Create.(pass: true)[:x].must_equal true }
end

#---
# with method
class DocsGuardMethodTest < Minitest::Spec
  #:method
  class Create < Trailblazer::Operation
    step Policy::Guard( :pass? )

    def pass?(options, pass:, **)
      pass
    end
    #~pipe-onlyy
    step :process

    def process(options, **)
      options["x"] = true
    end
    #~pipe-onlyy end
  end
  #:method end

  it { Create.(pass: false).inspect("x").must_equal %{<Result:false [nil] >} }
  it { Create.(pass: true).inspect("x").must_equal %{<Result:true [true] >} }
end

#---
# with name:
class DocsGuardNamedTest < Minitest::Spec
  #:name
  class Create < Trailblazer::Operation
    step Policy::Guard( ->(options, current_user:, **) { current_user }, name: :user )
    # ...
  end
  #:name end

  it { Create.(:current_user => nil   )["result.policy.user"].success?.must_equal false }
  it { Create.(:current_user => Module)["result.policy.user"].success?.must_equal true }

  it {
  #:name-result
  result = Create.(:current_user => true)
  result["result.policy.user"].success? #=> true
  #:name-result end
  }
end

#---
# dependency injection
class DocsGuardInjectionTest < Minitest::Spec
  #:di-op
  class Create < Trailblazer::Operation
    step Policy::Guard( ->(options, current_user:, **) { current_user == Module } )
  end
  #:di-op end

  it { Create.(:current_user => Module).inspect("").must_equal %{<Result:true [nil] >} }
  it {
    result =
  #:di-call
  Create.({},
    :current_user        => Module,
    "policy.default.eval" => Trailblazer::Operation::Policy::Guard.build(->(options, **) { false })
  )
  #:di-call end
    result.inspect("").must_equal %{<Result:false [nil] >} }
end

#---
# missing current_user throws exception
class DocsGuardMissingKeywordTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step Policy::Guard( ->(options, current_user:, **) { current_user == Module } )
  end

  it { assert_raises(ArgumentError) { Create.() } }
  it { Create.(:current_user => Module).success?.must_equal true }
end

#---
# before:
class DocsGuardPositionTest < Minitest::Spec
  #:before
  class Create < Trailblazer::Operation
    step :model!
    step Policy::Guard( :authorize! ),
      before: :model!
  end
  #:before end

  it { Trailblazer::Operation::Inspect.(Create).must_equal %{[>policy.default.eval,>model!]} }
  it do
    #:before-pipe
      Trailblazer::Operation::Inspect.(Create, style: :rows) #=>
       # 0 ========================>operation.new
       # 1 ==================>policy.default.eval
       # 2 ===============================>model!
    #:before-pipe end
  end
end
