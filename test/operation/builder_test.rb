require "test_helper"

class OperationBuilderTest < MiniTest::Spec
  class ParentOperation < Trailblazer::Operation
    def process(params)
    end

    class Sub < self
    end

    builds do |params|
      Sub if params[:sub]
    end
  end

  it { ParentOperation.run({}).last.class.must_equal ParentOperation }
  it { ParentOperation.run({sub: true}).last.class.must_equal ParentOperation::Sub }
  it { ParentOperation.({}).class.must_equal ParentOperation }
  it { ParentOperation.({sub: true}).class.must_equal ParentOperation::Sub }
end

class OperationBuilderClassTest < MiniTest::Spec
  class SuperOperation < Trailblazer::Operation
    builds do |params|
      self::Sub if params[:sub] # Sub is defined in ParentOperation.
    end
  end

  class ParentOperation < Trailblazer::Operation
    def process(params)
    end

    class Sub < self
    end

    self.builder_class = SuperOperation.builder_class
  end

  it { ParentOperation.({}).class.must_equal ParentOperation }
  it { ParentOperation.({sub: true}).class.must_equal ParentOperation::Sub }
end