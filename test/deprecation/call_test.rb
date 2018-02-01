require "test_helper"

require "trailblazer/deprecation/context"
require "trailblazer/deprecation/call"

class DeprecationCallTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step :create_model

    def create_model(options, params:, **)
      options["model"] = params.inspect
      options[:user] = options["current_user"]
    end
  end

  it "works with correct style" do
    result = Create.( params: { title: "Hello" } )
    result.inspect(:model, :user, :current_user, :params).must_equal %{<Result:false ["{:title=>\\\"Hello\\\"}", nil, nil, {:title=>\"Hello\"}] >}
  end

  it "works with correct style plus dependencies" do
    result = Create.( params: { title: "Hello" }, current_user: Object )
    result.inspect(:model, :user, :current_user, :params).must_equal %{<Result:true ["{:title=>\\\"Hello\\\"}", Object, Object, {:title=>\"Hello\"}] >}
  end

  it "converts old positional style" do
    result = Create.( { title: "Hello" }, "current_user" => user=Object )
    result.inspect(:model, :user, :current_user, :params).must_equal %{<Result:true ["{:title=>\\\"Hello\\\"}", Object, Object, {:title=>\"Hello\"}] >}
  end

  class WeirdStrongParameters < Hash
  end

  it "converts old positional style with StrongParameters" do
    params = WeirdStrongParameters.new
    params[:title] = "Hello"

    result = Create.( params, "current_user" => user=Object )

    result.inspect(:model, :user, :current_user, :params).must_equal %{<Result:true ["{:title=>\\\"Hello\\\"}", Object, Object, {:title=>\"Hello\"}] >}
  end
end
