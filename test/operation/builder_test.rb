require "test_helper"
require "trailblazer/operation/builder"

class BuilderTest < MiniTest::Spec
  class ParentOperation < Trailblazer::Operation
    include Builder

    puts "@@@@@dsf #{self["pipetree"].inspect}"

    class Sub < self
    end

    builds -> (options) do
      puts "@@@@@ #{options.inspect}"
      return Sub if options["params"][:sub]
    end
  end

  it { ParentOperation.({}).class.must_equal ParentOperation }
  it { ParentOperation.({ sub: true }).class.must_equal ParentOperation::Sub }
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
  end

  it { ParentOperation.({}).class.must_equal ParentOperation }
  it { ParentOperation.({ sub: true }).class.must_equal ParentOperation::Sub }
end
