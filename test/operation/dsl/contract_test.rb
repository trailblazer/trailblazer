require "test_helper"
require "trailblazer/operation/contract"

# contract Constant # new
# contract Constant, inherit: true # extend existing
# contract do end # extend existing || new
# contract Constant do .. end # new, extend new

class DslContractTest < MiniTest::Spec
  module Call
    def call(params)
      validate(params, model: model=OpenStruct.new) { contract.sync }
      model
    end

    def self.included(includer)
      includer.step Trailblazer::Operation::Model( OpenStruct, :new )
      includer.step Trailblazer::Operation::Contract::Build()
      includer.step Trailblazer::Operation::Contract::Validate()
      includer.step Trailblazer::Operation::Contract::Persist( method: :sync )
      # includer.> ->(op, *) { op["x"] = [] }
    end
  end

  # ---
  # Operation::["contract.default.class"]
  # Operation::["contract.default.class"]=
  class Create < Trailblazer::Operation
    include Contract
    self["contract.default.class"] = String
  end

  # reader method.
  # no subclassing.
  it { Create["contract.default.class"].must_equal String }

  class CreateOrFind < Create
  end

  # no inheritance with setter.
  it { CreateOrFind["contract.default.class"].must_equal nil }

  # ---
  # Op::contract Constant
  class Update < Trailblazer::Operation
    class IdContract < Reform::Form
      property :id
    end

    extend Contract::DSL
    contract IdContract

    include Call
  end

  # UT: subclasses contract.
  it { Update["contract.default.class"].superclass.must_equal Update::IdContract }
  # IT: only knows `id`.
  it { Update.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct id=1>} }

  # Op::contract with inheritance
  # no ::contract call.
  class Upgrade < Update
  end

  # UT: subclasses contract but doesn't share with parent.
  it { Upgrade["contract.default.class"].superclass.must_equal Update::IdContract }
  it { Upgrade["contract.default.class"].wont_equal Update["contract.default.class"] }
  # IT: only knows `id`.
  it { Upgrade.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct id=1>} }

  # ::contract B overrides old A contract.
  # this makes sure when calling contract(Constant), the old class gets wiped and is replaced with the new constant.
  class Upsert < Update
    class TitleContract < Reform::Form
      property :title
    end

    contract TitleContract
  end

  # UT: subclasses contract.
  it { Upsert["contract.default.class"].superclass.must_equal Upsert::TitleContract }
  # IT: only knows `title`.
  it { Upsert.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct title="Coaster">} }

  # ::contract B do ..end overrides and extends new.
  # using a constant will wipe out the existing class.
  class Upside < Update
    contract Upsert::TitleContract do
      property :id
    end
  end

  # UT: subclasses contract.
  it { Upside["contract.default.class"].superclass.must_equal Upsert::TitleContract }
  # IT: only knows `title`.
  it { Upside.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct title="Coaster", id=1>} }



  #---
  # contract do .. end
  # (with block)
  class Delete < Trailblazer::Operation
    include Call
    extend Contract::DSL
    contract do
      property :title
    end
  end

  # UT: contract path is "contract.default.class"
  it { Delete["contract.default.class"].definitions.keys.must_equal ["title"] }
  # IT: knows `title`.
  it { Delete.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct title=\"Coaster\">} }

  class Wipe < Trailblazer::Operation
    extend Contract::DSL

    self["x"] = contract do end
  end
  # UT: ::contract returns form class
  it { Wipe["x"].superclass.must_equal Reform::Form }

  # subsequent calls merge.
  class Remove < Trailblazer::Operation
    extend Contract::DSL
    include Call

    contract do
      property :title
    end

    contract do
      property :id
    end
  end

  # IT: knows `title` and `id`, since contracts get merged.
  it { Remove.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct title=\"Coaster\", id=1>} }






  # Operation::["contract.default.class"]
  # Operation::["contract.default.class"]=
  describe %{Operation::["contract.default.class"]} do

    class Update2 < Trailblazer::Operation
      self["contract.default.class"] = String
    end

    it { Update2["contract.default.class"].must_equal String }
  end

  describe "inheritance across operations" do
    # inheritance
    class Operation < Trailblazer::Operation
      extend Contract::DSL
      contract do
        property :title
        property :band
      end

      class JSON < self
        contract do # inherit Contract
          property :genre, validates: {presence: true}
          property :band, virtual: true
        end
      end

      class XML < self
      end
    end

    # inherits subclassed Contract.
    it { Operation["contract.default.class"].wont_equal Operation::JSON["contract.default.class"] }
    it { Operation::XML["contract.default.class"].superclass.must_equal Reform::Form }

    it do
      form = Operation["contract.default.class"].new(OpenStruct.new)
      form.validate({})#.must_equal true
      form.errors.to_s.must_equal "{}"

      form = Operation::JSON["contract.default.class"].new(OpenStruct.new)
      form.validate({})#.must_equal true
      form.errors.to_s.must_equal "{:genre=>[\"can't be blank\"]}"
    end

    # allows overriding options
    it do
      form = Operation::JSON["contract.default.class"].new(song = OpenStruct.new)
      form.validate({genre: "Punkrock", band: "Osker"}).must_equal true
      form.sync

      song.genre.must_equal "Punkrock"
      song.band.must_equal nil
    end
  end

  describe "Op.contract CommentForm" do
    class SongForm < Reform::Form
      property :songTitle, validates: {presence: true}
    end

    class OpWithExternalContract < Trailblazer::Operation
      extend Contract::DSL
      contract SongForm
      include Call
    end

    it { OpWithExternalContract.(params: {"songTitle"=> "Monsterparty"})["contract.default"].songTitle.must_equal "Monsterparty" }
  end

  describe "Op.contract CommentForm do .. end" do
    class DifferentSongForm < Reform::Form
      property :songTitle, validates: {presence: true}
    end

    class OpNotExtendingContract < Trailblazer::Operation
      extend Contract::DSL
      contract DifferentSongForm
      include Call
    end

    class OpExtendingContract < Trailblazer::Operation
      extend Contract::DSL
      contract DifferentSongForm do
        property :genre
      end
      include Call
    end

    # this operation copies DifferentSongForm and shouldn't have `genre`.
    it do
      contract = OpNotExtendingContract.(params: {"songTitle"=>"Monsterparty", "genre"=>"Punk"})["contract.default"]
      contract.songTitle.must_equal "Monsterparty"
      assert_raises(NoMethodError) { contract.genre }
    end

    # this operation copies DifferentSongForm and extends it with the property `genre`.
    it do
      contract = OpExtendingContract.(params: {"songTitle"=>"Monsterparty", "genre"=>"Punk"})["contract.default"]
      contract.songTitle.must_equal "Monsterparty"
      contract.genre.must_equal "Punk"
    end

    # of course, the original contract wasn't modified, either.
    it do
      assert_raises(NoMethodError) { DifferentSongForm.new(OpenStruct.new).genre }
    end
  end

  describe "Op.contract :name, Form" do
    class Follow < Trailblazer::Operation
      ParamsForm = Class.new

      extend Contract::DSL
      contract :params, ParamsForm
    end

    it { Follow["contract.params.class"].superclass.must_equal Follow::ParamsForm }
  end

  describe "Op.contract :name do..end" do
    class Unfollow < Trailblazer::Operation
      extend Contract::DSL
      contract :params do
        property :title
      end
    end

    it { Unfollow["contract.params.class"].superclass.must_equal Reform::Form }
  end

  # multiple ::contract calls.
  describe "multiple ::contract calls" do
    class Star < Trailblazer::Operation
      extend Contract::DSL
      contract do
        property :title
      end

      contract do
        property :id
      end
    end

    it { Star["contract.default.class"].definitions.keys.must_equal ["title", "id"]  }
  end
end
