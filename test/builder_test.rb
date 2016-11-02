require "test_helper"

require "trailblazer/builder"

# Tests agnostic TRB::Builder.
class MyBuilderTest < Minitest::Spec
  class ParentOperation < Trailblazer::Operation
    def process(*); self["x"] = ParentOperation; end

    class Sub < Trailblazer::Operation
      def process(*); self["x"] = ParentOperation::Sub; end
    end
  end

  # external builder.
  class MyBuilder < Trailblazer::Builder
    builds -> (params, *) do
      return ParentOperation::Sub if params[:sub]
      ParentOperation
    end
  end

  it { MyBuilder.({})["x"].must_equal ParentOperation }
  it { MyBuilder.({ sub: false })["x"].must_equal ParentOperation }
  it { MyBuilder.({ sub: true })["x"].must_equal ParentOperation::Sub }
end
