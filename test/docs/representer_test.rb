require "test_helper"
require "representable/json"

#---
# infer
class DocsRepresenterInferTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  #:infer
  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :id
    end

    step Model( Song, :new )
    step Contract::Build( constant: MyContract )
    step Contract::Validate( representer: Representer.infer(MyContract, format: Representable::JSON) )
    step Contract::Persist( method: :sync )
  end
  #:infer end

  let (:json) { MultiJson.dump(id: 1) }
  it { Create.( params: {}, document: json ).inspect(:model).must_equal %{<Result:true [#<struct DocsRepresenterInferTest::Song id=1, title=nil>] >} }
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

    step Model( Song, :new )
    step Contract::Build( constant: MyContract )
    step Contract::Validate( representer: MyRepresenter ) # :representer
    step Contract::Persist( method: :sync )
  end
  #:explicit-op end

  let (:json) { MultiJson.dump(id: 1) }
  it { Create.(params: {}, document: json).inspect(:model).must_equal %{<Result:true [#<struct DocsRepresenterExplicitTest::Song id=1, title=nil>] >} }
  it do
  #:explicit-call
  Create.(params: {}, document: '{"id": 1}')
  #:explicit-call end
  end

  #- render
  it do
  #:render
  result = Create.( params: {}, document: '{"id": 1}' )
  json   = result["representer.default.class"].new(result[:model]).to_json
  json #=> '{"id":1}'
  #:render end
  json.must_equal '{"id":1}'
  end

  #-
  # with dependency injection
  # overriding the JSON representer with an XML one.
  #:di-rep
  require "representable/xml"

  class MyXMLRepresenter < Representable::Decorator
    include Representable::XML
    property :id
  end
  #:di-rep end

  let (:xml) { %{<body><id>1</id></body>} }
  it do
  #:di-call
  result = Create.(params: {},
    document: '<body><id>1</id></body>',
    "representer.default.class" => MyXMLRepresenter # injection
  )
  #:di-call end
    result.inspect(:model).must_equal %{<Result:true [#<struct DocsRepresenterExplicitTest::Song id="1", title=nil>] >}
  end
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

    step Model( Song, :new )
    step Contract::Build( constant: MyContract )
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end

  let (:json) { MultiJson.dump(id: 1) }
  it { Create.(params: {}, document: json,
    "representer.default.class" => MyRepresenter).inspect(:model).must_equal %{<Result:true [#<struct DocsRepresenterDITest::Song id=1, title=nil>] >} }
end

#---
# inline
class DocsRepresenterInlineTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  #:inline
  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :id
    end

    extend Representer::DSL

    representer do
      property :id
    end

    step Model( Song, :new )
    step Contract::Build( constant: MyContract )
    step Contract::Validate( representer: self["representer.default.class"] )
    step Contract::Persist( method: :sync )
  end
  #:inline end

  let (:json) { MultiJson.dump(id: 1) }
  it { Create.(params: {}, document: json).inspect(:model).must_equal %{<Result:true [#<struct DocsRepresenterInlineTest::Song id=1, title=nil>] >} }
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

    step Model( Song, :find )
  end

  it do
    result =Show.(params: { id: 1 })
    json = result["representer.default.class"].new(result[:model]).to_json
    json.must_equal %{{"id":1}}
  end
end

#---
# naming

class DocsRepresenterNamingTest < Minitest::Spec
  MyRepresenter = Object

  #:naming
  class Create < Trailblazer::Operation
    extend Representer::DSL
    representer MyRepresenter
  end

  Create["representer.default.class"] #=> MyRepresenter
  #:naming end
  it { Create["representer.default.class"].must_be_kind_of MyRepresenter }
end

#---
# rendering
require "roar/json/hal"

class DocsRepresenterFullExampleTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def initialize(*)
      self.id = 1
    end
  end

  #:errors-rep
  class ErrorsRepresenter < Representable::Decorator
    include Representable::JSON
    collection :errors
  end
  #:errors-rep end

  #:full
  class Create < Trailblazer::Operation
    extend Contract::DSL
    extend Representer::DSL

    contract do
      property :title
      validates :title, presence: true
    end

    representer :parse do
      property :title
    end

    representer :render do
      include Roar::JSON::HAL

      property :id
      property :title
      link(:self) { "/songs/#{represented.id}" }
    end

    representer :errors, ErrorsRepresenter # explicit reference.

    step Model( Song, :new )
    step Contract::Build()
    step Contract::Validate( representer: self["representer.parse.class"] )
    step Contract::Persist( method: :sync )
  end
  #:full end

  it do
    result =Create.(params: {}, document: '{"title": "Tested"}')

    json = result["representer.render.class"].new(result[:model]).to_json

    json.must_equal %{{"id":1,"title":"Tested","_links":{"self":{"href":"/songs/1"}}}}


  #:full-call
  def create
    result = Create.(params, document: request.body.read)

    if result.success?
      result["representer.render.class"].new(result[:model]).to_json
    else
      result["representer.errors.class"].new(result["result.contract.default"]).to_json
    end
  end
  #:full-call end
  end

  it do
    result =Create.(params: {}, document: '{"title": ""}')

    if result.failure?
       json = result["representer.errors.class"].new(result["result.contract.default"]).to_json
    end

    json.must_equal %{{"errors":[["title","can't be blank"]]}}
  end
end
