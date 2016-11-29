require "test_helper"

class DocsGuardProcTest < Minitest::Spec

  #--
  # with proc
  #:proc
  class Create < Trailblazer::Operation
    self.| Policy::Guard[ ->(options) { options["params"][:pass] } ]
    self.| :process

    def process(*)
      self["x"] = true
    end
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

class DocsGuardClassLevelTest < Minitest::Spec
  #---
  # class-level guard
  #:class-level
  class Create < Trailblazer::Operation
    self.| Policy::Guard[ ->(options) { options["current_user"] == Module } ],
      before: "operation.new"
    self.| ->(options) { options["x"] = true }
  end
  #:class-level end

  it { Create.(); Create["result.policy"].must_equal nil }
  it { Create.({}, "current_user" => Module)["x"].must_equal true }
  it { Create.({}                          )["x"].must_equal nil }
end

# TODO:
#policy.default
# no policy write on operation class.
