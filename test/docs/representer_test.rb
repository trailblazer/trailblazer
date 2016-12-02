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

  #:explicit-rep
  class MyRepresenter < Representable::Decorator
    include Representable::JSON
    property :id
  end
  #:explicit-rep end

  #:explicit-op
  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :id
    end

    self.| Model[ Song, :new ]
    self.| Contract::Build[ constant: MyContract ]
    self.| Contract::Validate[ representer: MyRepresenter ]
    self.| Persist[ method: :sync ]
  end
  #:explicit-op end

  let (:json) { MultiJson.dump(id: 1) }
  it { Create.({}, "document.json" => json).inspect("model").must_equal %{<Result:true [#<struct DocsRepresenterExplicitTest::Song id=1, title=nil>] >} }
  it do
  #:explicit-call
  Create.({}, "document.json" => '{"id": 1}')
  #:explicit-call end
  end

  #-
  # with dependency injection
  # overriding the JSON representer with an XML one.
  require "representable/xml"
  class MyXMLRepresenter < Representable::Decorator
    include Representable::XML
    property :id
    alias_method :from_json, :from_xml # FIXME. introduce #parse.
  end

  let (:xml) { %{<body><id>1</id></body>} }
  it { Create.({}, "document.json" => xml,
    "representer.default.class" => MyXMLRepresenter).inspect("model").must_equal %{<Result:true [#<struct DocsRepresenterExplicitTest::Song id="1", title=nil>] >} }
end

#---
# dependency injection
class DocsRepresenterDITest < Minitest::Spec
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
    self.| Contract::Validate[]
    self.| Persist[ method: :sync ]
  end

  let (:json) { MultiJson.dump(id: 1) }
  it { Create.({}, "document.json" => json,
    "representer.default.class" => MyRepresenter).inspect("model").must_equal %{<Result:true [#<struct DocsRepresenterDITest::Song id=1, title=nil>] >} }
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
