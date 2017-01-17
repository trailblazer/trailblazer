require "test_helper"
require "dry/container"

class DryContainerTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  class MyContract < Reform::Form
    property :title
    validates :title, length: 2..33
  end

  my_container = Dry::Container.new
  my_container.register("contract.default.class", MyContract)
  # my_container.namespace("contract") do
  #   register("create") { Array }
  # end

  #---
  #- dependency injection
  #- with Dry-container
  class Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build()
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end
  #:key end

  it { Create.({ title: "A" }, {}, my_container).inspect("model").must_equal %{<Result:false [#<struct DryContainerTest::Song id=nil, title=nil>] >} }
  it { Create.({ title: "Anthony's Song" }, {}, my_container).inspect("model").must_equal %{<Result:true [#<struct DryContainerTest::Song id=nil, title="Anthony's Song">] >} }
end
