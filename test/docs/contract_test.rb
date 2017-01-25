require "test_helper"

class DocsContractOverviewTest < Minitest::Spec
  Song = Struct.new(:length, :title)

  #:overv-reform
  # app/concepts/song/create.rb
  class Create < Trailblazer::Operation
    #~bla
    extend Contract::DSL

    contract do
      property :title
      #~contractonly
      property :length

      validates :title,  presence: true
      validates :length, numericality: true
      #~contractonly end
    end
    #~contractonly

    #~bla end
    step Model( Song, :new )
    step Contract::Build()
    step Contract::Validate()
    step Contract::Persist( method: :sync )
    #~contractonly end
  end
  #:overv-reform end

  puts Create["pipetree"].inspect(style: :rows)

=begin
  #:overv-reform-pipe
   0 =======================>>operation.new
   1 ==========================&model.build
   2 =======================>contract.build
   3 ==============&validate.params.extract
   4 ====================&contract.validate
   5 =========================&persist.save
  #:overv-reform-pipe end
=end

  it do
    assert Create["contract.default.class"] < Reform::Form
  end

  #- result
  it do
    #:result
    result = Create.({ length: "A" })

    result["result.contract.default"].success?        #=> false
    result["result.contract.default"].errors          #=> Errors object
    result["result.contract.default"].errors.messages #=> {:length=>["is not a number"]}

    #:result end
    result["result.contract.default"].success?.must_equal false
    result["result.contract.default"].errors.messages.must_equal ({:title=>["can't be blank"], :length=>["is not a number"]})
  end
end

class DocsContractNameTest < Minitest::Spec
  Song = Struct.new(:length, :title)

  #:contract-name
  # app/concepts/comment/update.rb
  class Update < Trailblazer::Operation
    #~contract
    extend Contract::DSL

    contract :params do
      property :id
      validates :id,  presence: true
    end
    #~contract end
    #~pipe
    step Model( Song, :new )
    step Contract::Build( name: "params" )
    step Contract::Validate( name: "params" )
    #~pipe end
  end
  #:contract-name end
end

class DocsContractReferenceTest < Minitest::Spec
  MyContract = Class.new
  #:contract-ref
  # app/concepts/comment/update.rb
  class Update < Trailblazer::Operation
    #~contract
    extend Contract::DSL
    contract :user, MyContract
  end
  #:contract-ref end
end

#---
# contract MyContract
class DocsContractExplicitTest < Minitest::Spec
  Song = Struct.new(:length, :title)

  #:reform-inline
  class MyContract < Reform::Form
    property :title
    property :length

    validates :title,  presence: true
    validates :length, numericality: true
  end
  #:reform-inline end

  #:reform-inline-op
  # app/concepts/comment/create.rb
  class Create < Trailblazer::Operation
    extend Contract::DSL

    contract MyContract

    step Model( Song, :new )
    step Contract::Build()
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end
  #:reform-inline-op end
end

#- Validate with manual key extraction
class DocsContractSeparateKeyTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #:key-extr
  class Create < Trailblazer::Operation
    extend Contract::DSL

    contract do
      property :title
    end

    def type
      "evergreen" # this is how you could do polymorphic lookups.
    end

    step Model( Song, :new )
    step Contract::Build()
    step :extract_params!
    step Contract::Validate( skip_extract: true )
    step Contract::Persist( method: :sync )

    def extract_params!(options)
      options["contract.default.params"] = options["params"][type]
    end
  end
  #:key-extr end

  it { Create.({ }).inspect("model").must_equal %{<Result:false [#<struct DocsContractSeparateKeyTest::Song id=nil, title=nil>] >} }
  it { Create.({"evergreen" => { title: "SVG" }}).inspect("model").must_equal %{<Result:true [#<struct DocsContractSeparateKeyTest::Song id=nil, title="SVG">] >} }
end

#---
#- Contract::Build( constant: XXX )
class ContractConstantTest < Minitest::Spec
  Song = Struct.new(:title, :length) do
    def save
      true
    end
  end

  #:constant-contract
  # app/concepts/song/contract/create.rb
  module Song::Contract
    class Create < Reform::Form
      property :title
      property :length

      validates :title,  length: 2..33
      validates :length, numericality: true
    end
  end
  #:constant-contract end

  #:constant
  class Song::Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build( constant: Song::Contract::Create )
    step Contract::Validate()
    step Contract::Persist()
  end
  #:constant end

  it { Song::Create.({ title: "A" }).inspect("model").must_equal %{<Result:false [#<struct ContractConstantTest::Song title=nil, length=nil>] >} }
  it { Song::Create.({ title: "Anthony's Song", length: 12 }).inspect("model").must_equal %{<Result:true [#<struct ContractConstantTest::Song title="Anthony's Song", length=12>] >} }
  it do
    #:constant-result
    result = Song::Create.( title: "A" )
    result.success? #=> false
    result["contract.default"].errors.messages
      #=> {:title=>["is too short (minimum is 2 characters)"], :length=>["is not a number"]}
    #:constant-result end

    #:constant-result-true
    result = Song::Create.( title: "Rising Force", length: 13 )
    result.success? #=> true
    result["model"] #=> #<Song title="Rising Force", length=13>
    #:constant-result-true end
  end

  #---
  # Song::New
  #:constant-new
  class Song::New < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build( constant: Song::Contract::Create )
  end
  #:constant-new end

  it { Song::New.().inspect("model").must_equal %{<Result:true [#<struct ContractConstantTest::Song title=nil, length=nil>] >} }
  it { Song::New.()["contract.default"].model.inspect.must_equal %{#<struct ContractConstantTest::Song title=nil, length=nil>} }
  it do
    #:constant-new-result
    result = Song::New.()
    result["model"] #=> #<struct Song title=nil, length=nil>
    result["contract.default"]
      #=> #<Song::Contract::Create model=#<struct Song title=nil, length=nil>>
    #:constant-new-result end
  end

  #---
  #:validate-only
  class Song::ValidateOnly < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build( constant: Song::Contract::Create )
    step Contract::Validate()
  end
  #:validate-only end

  it { Song::ValidateOnly.().inspect("model").must_equal %{<Result:false [#<struct ContractConstantTest::Song title=nil, length=nil>] >} }
  it do
    result = Song::ValidateOnly.({ title: "Rising Forse", length: 13 })
    result.inspect("model").must_equal %{<Result:true [#<struct ContractConstantTest::Song title=nil, length=nil>] >}
  end

  it do
    #:validate-only-result-false
    result = Song::ValidateOnly.({}) # empty params
    result.success? #=> false
    #:validate-only-result-false end
  end

  it do
    #:validate-only-result
    result = Song::ValidateOnly.({ title: "Rising Force", length: 13 })

    result.success? #=> true
    result["model"] #=> #<struct Song title=nil, length=nil>
    result["contract.default"].title #=> "Rising Force"
    #:validate-only-result end
  end
end

#---
#- Validate( key: :song )
class DocsContractKeyTest < Minitest::Spec
  Song = Class.new(ContractConstantTest::Song)

  module Song::Contract
    Create = ContractConstantTest::Song::Contract::Create
  end

  #:key
  class Song::Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build( constant: Song::Contract::Create )
    step Contract::Validate( key: "song" )
    step Contract::Persist( )
  end
  #:key end

  it { Song::Create.({}).inspect("model", "result.contract.default.extract").must_equal %{<Result:false [#<struct DocsContractKeyTest::Song title=nil, length=nil>, nil] >} }
  it { Song::Create.({"song" => { title: "SVG", length: 13 }}).inspect("model").must_equal %{<Result:true [#<struct DocsContractKeyTest::Song title=\"SVG\", length=13>] >} }
  it do
    #:key-res
    result = Song::Create.({ "song" => { title: "Rising Force", length: 13 } })
    result.success? #=> true
    #:key-res end

    #:key-res-false
    result = Song::Create.({ title: "Rising Force", length: 13 })
    result.success? #=> false
    #:key-res-false end
  end
end

#- Contract::Build[ constant: XXX, name: AAA ]
class ContractNamedConstantTest < Minitest::Spec
  Song = Class.new(ContractConstantTest::Song)

  module Song::Contract
    Create = ContractConstantTest::Song::Contract::Create
  end

  #:constant-name
  class Song::Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build(    name: "form", constant: Song::Contract::Create )
    step Contract::Validate( name: "form" )
    step Contract::Persist(  name: "form" )
  end
  #:constant-name end

  it { Song::Create.({ title: "A" }).inspect("model").must_equal %{<Result:false [#<struct ContractNamedConstantTest::Song title=nil, length=nil>] >} }
  it { Song::Create.({ title: "Anthony's Song", length: 13 }).inspect("model").must_equal %{<Result:true [#<struct ContractNamedConstantTest::Song title="Anthony's Song", length=13>] >} }

  it do
    #:name-res
    result = Song::Create.({ title: "A" })
    result["contract.form"].errors.messages #=> {:title=>["is too short (minimum is 2 ch...
    #:name-res end
  end
end

#---
#- dependency injection
#- contract class
class ContractInjectConstantTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #:di-constant-contract
  class MyContract < Reform::Form
    property :title
    validates :title, length: 2..33
  end
  #:di-constant-contract end
  #:di-constant
  class Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build()
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end
  #:di-constant end

  it do
  #:di-contract-call
  Create.(
    { title: "Anthony's Song" },
    "contract.default.class" => MyContract
  )
  #:di-contract-call end
  end
  it { Create.({ title: "A" }, "contract.default.class" => MyContract).inspect("model").must_equal %{<Result:false [#<struct ContractInjectConstantTest::Song id=nil, title=nil>] >} }
  it { Create.({ title: "Anthony's Song" }, "contract.default.class" => MyContract).inspect("model").must_equal %{<Result:true [#<struct ContractInjectConstantTest::Song id=nil, title="Anthony's Song">] >} }
end

class DryValidationContractTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #---
  # DRY-validation params validation before op,
  # plus main contract.
  #- result.path
  #:dry-schema
  require "dry/validation"
  class Create < Trailblazer::Operation
    extend Contract::DSL

    # contract to verify params formally.
    contract "params", (Dry::Validation.Schema do
      required(:id).filled
    end)
    #~form
    # domain validations.
    contract "form" do
      property :title
      validates :title, length: 1..3
    end
    #~form end

    step Contract::Validate( name: "params" )
    #~form
    step Model( Song, :new )                             # create the op's main model.
    step Contract::Build( name: "form" )                 # create the Reform contract.
    step Contract::Validate( name: "form" )              # validate the Reform contract.
    step Contract::Persist( method: :sync, name: "form" ) # persist the contract's data via the model.
    #~form end
  end
  #:dry-schema end

  puts "@@@@@ #{Create["pipetree"].inspect(style: :rows)}"

  it { Create.({}).inspect("model", "result.contract.params").must_equal %{<Result:false [nil, #<Dry::Validation::Result output={} errors={:id=>[\"is missing\"]}>] >} }
  it { Create.({ id: 1 }).inspect("model", "result.contract.params").must_equal %{<Result:false [#<struct DryValidationContractTest::Song id=nil, title=nil>, #<Dry::Validation::Result output={:id=>1} errors={}>] >} }
  # it { Create.({ id: 1, title: "" }).inspect("model", "result.contract.form").must_equal %{<Result:false [#<struct DryValidationContractTest::Song id=nil, title=nil>] >} }
  it { Create.({ id: 1, title: "" }).inspect("model").must_equal %{<Result:false [#<struct DryValidationContractTest::Song id=nil, title=nil>] >} }
  it { Create.({ id: 1, title: "Yo" }).inspect("model").must_equal %{<Result:true [#<struct DryValidationContractTest::Song id=nil, title="Yo">] >} }

  #:dry-schema-first
  require "dry/validation"
  class Delete < Trailblazer::Operation
    extend Contract::DSL

    contract "params", (Dry::Validation.Schema do
      required(:id).filled
    end)

    step Contract::Validate( name: "params" ), before: "operation.new"
    #~more
    #~more end
  end
  #:dry-schema-first end
end

class DryExplicitSchemaTest < Minitest::Spec
  #:dry-schema-explsch
  # app/concepts/comment/contract/params.rb
  require "dry/validation"
  MySchema = Dry::Validation.Schema do
    required(:id).filled
  end
  #:dry-schema-explsch end

  #:dry-schema-expl
  # app/concepts/comment/delete.rb
  class Delete < Trailblazer::Operation
    extend Contract::DSL
    contract "params", MySchema

    step Contract::Validate( name: "params" ), before: "operation.new"
  end
  #:dry-schema-expl end
end

class DocContractBuilderTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #---
  #- builder:
  #:builder-option
  class Create < Trailblazer::Operation
    extend Contract::DSL

    contract do
      property :title
      property :current_user, virtual: true
      validates :current_user, presence: true
    end

    step Model( Song, :new )
    step Contract::Build( builder: :default_contract! )
    step Contract::Validate()
    step Contract::Persist( method: :sync )

    def default_contract!(options, constant:, model:, **)
      constant.new(model, current_user: self["current_user"])
    end
  end
  #:builder-option end

  it { Create.({}).inspect("model").must_equal %{<Result:false [#<struct DocContractBuilderTest::Song id=nil, title=nil>] >} }
  it { Create.({ title: 1}, "current_user" => Module).inspect("model").must_equal %{<Result:true [#<struct DocContractBuilderTest::Song id=nil, title=1>] >} }

  #- proc
  class Update < Trailblazer::Operation
    extend Contract::DSL

    contract do
      property :title
      property :current_user, virtual: true
      validates :current_user, presence: true
    end

    step Model( Song, :new )
    #:builder-proc
    step Contract::Build( builder: ->(options, constant:, model:, **) {
      constant.new(model, current_user: options["current_user"])
    })
    #:builder-proc end
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end

  it { Update.({}).inspect("model").must_equal %{<Result:false [#<struct DocContractBuilderTest::Song id=nil, title=nil>] >} }
  it { Update.({ title: 1}, "current_user" => Module).inspect("model").must_equal %{<Result:true [#<struct DocContractBuilderTest::Song id=nil, title=1>] >} }
end

class DocContractTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #---
  # with contract block, and inheritance, the old way.
  class Block < Trailblazer::Operation
    extend Contract::DSL
    contract do
      property :title
    end

    step Model( Song, :new )
    step Contract::Build()            # resolves to "contract.class.default" and is resolved at runtime.
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end

  it { Block.({}).inspect("model").must_equal %{<Result:true [#<struct DocContractTest::Song id=nil, title=nil>] >} }
  it { Block.({ id:1, title: "Fame" }).inspect("model").must_equal %{<Result:true [#<struct DocContractTest::Song id=nil, title="Fame">] >} }

  class Breach < Block
    contract do
      property :id
    end
  end

  it { Breach.({ id:1, title: "Fame" }).inspect("model").must_equal %{<Result:true [#<struct DocContractTest::Song id=1, title="Fame">] >} }

  #-
  # with constant.
  class Break < Block
    class MyContract < Reform::Form
      property :id
    end
    # override the original block as if it's never been there.
    contract MyContract
  end

  it { Break.({ id:1, title: "Fame" }).inspect("model").must_equal %{<Result:true [#<struct DocContractTest::Song id=1, title=nil>] >} }
end




