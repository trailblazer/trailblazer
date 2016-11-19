require "test_helper"

class DocContractTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  #---
  # Arbitrary params validation before op.
  #- Contract[ constant: XXX ]
  class Attach < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
      validates :title, length: 2..33
    end

    self.& ->(input, options) { options["params"].has_key?(:title) }
    self.| Model[Song, :create]
    self.| Contract[constant: MyContract]
    self.| Contract::Validate[]
    self.| Persist[method: :sync]
  end

  it { Attach.({}).inspect("model").must_equal %{<Result:false [nil] >} }
  it { Attach.({ title: "A" }).inspect("model").must_equal %{<Result:false [#<struct DocContractTest::Song id=nil, title=nil>] >} }
  it { Attach.({ title: "Anthony's Song" }).inspect("model").must_equal %{<Result:true [#<struct DocContractTest::Song id=nil, title="Anthony's Song">] >} }

  require "dry/validation"
  #---
  # DRY-validation params validation before op,
  # plus main contract.
  #- result.path
  class Add < Trailblazer::Operation
    extend Contract::DSL

    # contract to verify params formally.
    contract "params", (Dry::Validation.Schema do
      required(:id).filled
    end)

    # domain validations.
    contract "form" do
      property :title
      validates :title, length: 1..3
    end

    self.| Contract::Validate[name: "params"]                # run DRY-validation contract against the params structure.
    self.| Model[Song, :create]                              # create the op's main model.
    self.| Contract[name: "form"]                            # create the Reform contract.
    self.| Contract::Validate[name: "form"]                  # validate the Reform contract.
    self.| Persist[method: :sync, contract: "contract.form"] # persist the contract's data via the model.
  end

  it { Add.({}).inspect("model", "result.contract.params").must_equal %{<Result:false [nil, #<Dry::Validation::Result output={} errors={:id=>[\"is missing\"]}>] >} }
  it { Add.({ id: 1 }).inspect("model", "result.contract.params").must_equal %{<Result:false [#<struct DocContractTest::Song id=nil, title=nil>, #<Dry::Validation::Result output={:id=>1} errors={}>] >} }
  # it { Add.({ id: 1, title: "" }).inspect("model", "result.contract.form").must_equal %{<Result:false [#<struct DocContractTest::Song id=nil, title=nil>] >} }
  it { Add.({ id: 1, title: "" }).inspect("model").must_equal %{<Result:false [#<struct DocContractTest::Song id=nil, title=nil>] >} }
  it { Add.({ id: 1, title: "Yo" }).inspect("model").must_equal %{<Result:true [#<struct DocContractTest::Song id=nil, title="Yo">] >} }

  #-
  # own builder
  class Allocate < Trailblazer::Operation
    extend Contract::DSL

    contract do
      property :title
      property :current_user, virtual: true

      validates :current_user, presence: true
    end

    self.| Model[Song, :create]
    self.| Contract[builder: :default_contract!]
    self.| Contract::Validate[]
    self.| Persist[method: :sync]

    def default_contract!
      self["contract.default.class"].new(self["model"], current_user: self["user.current"])
    end
  end

  it { Allocate.({}).inspect("model").must_equal %{<Result:false [#<struct DocContractTest::Song id=nil, title=nil>] >} }
  it { Allocate.({ title: 1}, "user.current" => Module).inspect("model").must_equal %{<Result:true [#<struct DocContractTest::Song id=nil, title=1>] >} }

  #---
  # with contract block, and inheritance, the old way.
  class Block < Trailblazer::Operation
    extend Contract::DSL
    contract do
      property :title
    end

    self.| Model[Song, :create]
    self.| Contract[]            # resolves to "contract.class.default" and is resolved at runtime.
    self.| Contract::Validate[]
    self.| Persist[method: :sync]
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




