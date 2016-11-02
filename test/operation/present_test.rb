require "test_helper"

require "trailblazer/operation/present"

class PresentTest < Minitest::Spec
  class Create < Trailblazer::Operation
    include Test::ReturnCall
    include Present

    include Model::Builder
    def model!(*); Object end

    def call(params)
      "#call run!"
    end
  end

  it do
    result = Create.present
    result["model"].must_equal Object
  end

  it { Create.().must_equal "#call run!" }
end
