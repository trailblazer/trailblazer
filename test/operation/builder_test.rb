require "test_helper"
require "trailblazer/operation/builder"

class BuilderTest < MiniTest::Spec
  class ParentOperation < Trailblazer::Operation
    include Builder

    class Sub < self
    end

    builds -> (options) do
      return Sub if options["params"][:sub]
    end

    def process(*); self["x"] = self.class end
  end

  it { ParentOperation.({})["x"].must_equal ParentOperation }
  it { ParentOperation.({ sub: true })["x"].must_equal ParentOperation::Sub }
end

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
    self.builder_class = SuperOperation.builder_class

    def process(*); self["x"] = self.class end
  end

  it { ParentOperation.({})["x"].must_equal ParentOperation }
  it { ParentOperation.({ sub: true })["x"].must_equal ParentOperation::Sub }
end
