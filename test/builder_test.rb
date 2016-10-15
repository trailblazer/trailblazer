require "test_helper"

require "trailblazer/builder"

class BuilderTest < Minitest::Spec
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

  it { MyBuilder.({})[:operation].class.must_equal ParentOperation }
  it { MyBuilder.({ sub: false })[:operation].class.must_equal ParentOperation }
  it { MyBuilder.({ sub: true })[:operation].class.must_equal ParentOperation::Sub }
end
