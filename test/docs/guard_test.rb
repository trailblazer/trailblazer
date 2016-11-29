require "test_helper"

class DocsGuardProcTest < Minitest::Spec
  #--
  # with proc
  #:proc
  class Create < Trailblazer::Operation
    self.| Policy::Guard[ ->(options) { options["params"][:pass] } ]
    self.| :process
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
  it { Create.(pass: true)["result.policy"].success?.must_equal true }
  it { Create.(pass: false)["result.policy"].success?.must_equal false }




   #---
  #- Guard inheritance
  class New < Create
  end

  it { New["pipetree"].inspect.must_equal %{[>>operation.new,&policy.guard.evaluate,>process]} }
end

class DocsGuardTest < Minitest::Spec
  #---
  # with Callable
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
    self.| Policy::Guard[ MyGuard.new ]
    self.| :process
    #~pipe-only
    def process(*); self[:x] = true; end
    #~pipe-only end
  end
  #:callable-op end

  it { Create.(pass: false)[:x].must_equal nil }
  it { Create.(pass: true)[:x].must_equal true }
end

class DocsGuardClassLevelTest < Minitest::Spec
  #---
  # class-level guard
  #:class-level
  class Create < Trailblazer::Operation
    self.| Policy::Guard[ ->(options) { options["current_user"] == Module } ],
      before: "operation.new"
    #~pipe--only
    self.| ->(options) { options["x"] = true }
    #~pipe--only end
  end
  #:class-level end

  it { Create.(); Create["result.policy"].must_equal nil }
  it { Create.({}, "current_user" => Module)["x"].must_equal true }
  it { Create.({}                          )["x"].must_equal nil }
end

# TODO:
#policy.default
# no policy write on operation class.
