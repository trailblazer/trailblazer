require "test_helper"
require "representable/json"

#---
# infer
class DocsRepresenterInferTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :id
    end

    self.| Model[ Song, :new ]
    self.| Contract::Build[ constant: MyContract ]
    self.| Contract::Validate[ representer: Representer.infer(MyContract) ]
    self.| Persist[ method: :sync ]
  end

  let (:json) { MultiJson.dump(id: 1) }
  it { Create.({}, "document.json" => json).inspect("model").must_equal %{<Result:true [#<struct DocsRepresenterInferTest::Song id=1, title=nil>] >} }
end

#---
# explicit
class DocsRepresenterExplicitTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  class MyRepresenter < Representable::Decorator
    include Representable::JSON
    property :id
  end

  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :id
    end

    self.| Model[ Song, :new ]
    self.| Contract::Build[ constant: MyContract ]
    self.| Contract::Validate[ representer: MyRepresenter ]
    self.| Persist[ method: :sync ]
  end

  let (:json) { MultiJson.dump(id: 1) }
  it { Create.({}, "document.json" => json).inspect("model").must_equal %{<Result:true [#<struct DocsRepresenterExplicitTest::Song id=1, title=nil>] >} }
end

#---
# inline
class DocsRepresenterInlineTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :id
    end

    extend Representer::DSL
    representer do
      property :id
    end

    self.| Model[ Song, :new ]
    self.| Contract::Build[ constant: MyContract ]
    self.| Contract::Validate[ representer: self["representer.default.class"] ]
    self.| Persist[ method: :sync ]
  end

  let (:json) { MultiJson.dump(id: 1) }
  it { Create.({}, "document.json" => json).inspect("model").must_equal %{<Result:true [#<struct DocsRepresenterInlineTest::Song id=1, title=nil>] >} }
end

#---
# rendering
class DocsRepresenterManualRenderTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find(id)
      new(id)
    end
  end

  class Show < Trailblazer::Operation
    extend Representer::DSL
    representer do
      property :id
    end

    self.| Model[ Song, :find ]
  end

  it do
    result =Show.({ id: 1 })
    json = result["representer.default.class"].new(result["model"]).to_json
    json.must_equal %{{"id":1}}
  end
end
