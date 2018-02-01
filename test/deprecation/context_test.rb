require "test_helper"

require "trailblazer/deprecation/context"

class DeprecationContextTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step :create_model

    def create_model(options, params:, **)
      options["model"] = params.inspect
      options[:user] = options["current_user"]
    end
  end

  it do
    result = Create.( "params"=> {title: "Hello"}, "current_user" => user=Object)
    result.inspect(:model, :user, :current_user, :params).must_equal %{<Result:true ["{:title=>\\\"Hello\\\"}", Object, Object, {:title=>\"Hello\"}] >}
  end
end
