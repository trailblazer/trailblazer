require "test_helper"

require "trailblazer/builder"

# Tests agnostic TRB::Builder.
class MyBuilderTest < Minitest::Spec
  class ParentOperation < Trailblazer::Operation
    class Sub < Trailblazer::Operation
    end
  end

  # external builder.
  class MyBuilder < Trailblazer::Builder
    builds -> (params, *) do
      return ParentOperation::Sub if params[:sub]
      ParentOperation
    end
  end

  it { MyBuilder.({}).class.must_equal ParentOperation }
  it { MyBuilder.({ sub: false }).class.must_equal ParentOperation }
  it { MyBuilder.({ sub: true }).class.must_equal ParentOperation::Sub }
end
