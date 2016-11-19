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

    self.| Contract::Validate[name: "params"]
    self.| Model[Song, :create]
    self.| Contract[name: "form"]
    self.| Contract::Validate[name: "form"]
    self.| Persist[method: :sync, contract: "contract.form"]
  end

  it { Add.({}).inspect("model").must_equal %{<Result:false [nil] >} }
  it { Add.({ id: 1 }).inspect("model").must_equal %{<Result:false [#<struct DocContractTest::Song id=nil, title=nil>] >} }
  it { Add.({ id: 1, title: "" }).inspect("model").must_equal %{<Result:false [#<struct DocContractTest::Song id=nil, title=nil>] >} }
  it { Add.({ id: 1, title: "Yo" }).inspect("model").must_equal %{<Result:true [#<struct DocContractTest::Song id=nil, title="Yo">] >} }

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




