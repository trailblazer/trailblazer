require "test_helper"
require "trailblazer/operation/builder"

class BuilderTest < MiniTest::Spec
  #---
  # pass proc to Builder[]
  # this is the minimalistic way.
  class A < Trailblazer::Operation
    builds = ->(options) do
      return B if options["params"][:sub]
      A
    end

    self.| Builder[ builds ]
    self.| Call

    class B < A
    end

    def process(*); self["x"] = self.class end
  end

  it { A.()["x"].must_equal A }
  it { A.({ sub: true })["x"].must_equal A::B }
  it { A::B["builder"].must_equal nil }

  #---
  #- Builder inheritance
  class B < A
  end

  it { B["pipetree"].inspect.must_equal %{[>>operation.new,>Call]} }

  #---
  # use Builder DSL
  # you don't need to include Builder in the pipetree
  class ParentOperation < Trailblazer::Operation
    class Sub < self
    end

    include Builder
    builds -> (options) do
      return Sub if options["params"][:sub]
    end

    def process(*); self["x"] = self.class end
    self.| Call
  end

  it { ParentOperation.({})["x"].must_equal ParentOperation }
  it { ParentOperation.({ sub: true })["x"].must_equal ParentOperation::Sub }
end

#---
# copying via ["builder"]
class OperationBuilderClassTest < MiniTest::Spec
  class SuperOperation < Trailblazer::Operation
    include Builder

    builds do |options|
      self::Sub if options["params"][:sub] # Sub is defined in ParentOperation.
    end
  end

  class ParentOperation < Trailblazer::Operation
    def process(params)
    end

    class Sub < self
    end

    include Builder
    # self["builder_class"] = SuperOperation["builder_class"]
    self["builder"] = SuperOperation["builder"]

    def process(*); self["x"] = self.class end
    self.| Call
  end

  it { ParentOperation.({})["x"].must_equal ParentOperation }
  it { ParentOperation.({ sub: true })["x"].must_equal ParentOperation::Sub }
end
