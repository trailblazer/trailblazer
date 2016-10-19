require "test_helper"
require "trailblazer/operation/contract"

class DslContractTest < MiniTest::Spec
  module SongProcess
    def process(params)
      validate(params, @model = OpenStruct.new)
    end
  end

  # Operation::["contract.class"]
  # Operation::["contract.class"]=
  describe %{Operation::["contract.class"]} do
    class Create < Trailblazer::Operation
      include Contract
      contract String
    end

    it { Create["contract.class"].superclass.must_equal String }

    class Update < Trailblazer::Operation
      include Contract
      self["contract.class"] = String
    end

    it { Update["contract.class"].must_equal String }
  end

  describe "inheritance across operations" do
    # inheritance
    class Operation < Trailblazer::Operation
      include Contract
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
    it { Operation["contract.class"].wont_equal Operation::JSON["contract.class"] }
    it { Operation::XML["contract.class"].superclass.must_equal Reform::Form }

    it do
      form = Operation["contract.class"].new(OpenStruct.new)
      form.validate({})#.must_equal true
      form.errors.to_s.must_equal "{}"

      form = Operation::JSON["contract.class"].new(OpenStruct.new)
      form.validate({})#.must_equal true
      form.errors.to_s.must_equal "{:genre=>[\"can't be blank\"]}"
    end

    # allows overriding options
    it do
      form = Operation::JSON["contract.class"].new(song = OpenStruct.new)
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
      include Contract
      contract SongForm
      include SongProcess
    end

    it { OpWithExternalContract.("songTitle"=> "Monsterparty")[:operation].contract.songTitle.must_equal "Monsterparty" }
  end

  describe "Op.contract CommentForm do .. end" do
    class DifferentSongForm < Reform::Form
      property :songTitle, validates: {presence: true}
    end

    class OpNotExtendingContract < Trailblazer::Operation
      include Contract
      contract DifferentSongForm
      include SongProcess
    end

    class OpExtendingContract < Trailblazer::Operation
      include Contract
      contract DifferentSongForm do
        property :genre
      end
      include SongProcess
    end

    # this operation copies DifferentSongForm and shouldn't have `genre`.
    it do
      contract = OpNotExtendingContract.("songTitle"=>"Monsterparty", "genre"=>"Punk")[:operation].contract
      contract.songTitle.must_equal "Monsterparty"
      assert_raises(NoMethodError) { contract.genre }
    end

    # this operation copies DifferentSongForm and extends it with the property `genre`.
    it do
      contract = OpExtendingContract.("songTitle"=>"Monsterparty", "genre"=>"Punk")[:operation].contract
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

      include Contract
      contract :params, ParamsForm
    end

    it { Follow["contract.params.class"].superclass.must_equal Follow::ParamsForm }
  end

  describe "Op.contract :name do..end" do
    class Unfollow < Trailblazer::Operation
      include Contract
      contract :params do
        property :title
      end
    end

    it { Unfollow["contract.params.class"].superclass.must_equal Reform::Form }
  end

  # multiple ::contract calls.
  describe "multiple ::contract calls" do
    class Star < Trailblazer::Operation
      include Contract
      contract do
        property :title
      end

      contract do
        property :id
      end
    end

    it { Star["contract.class"].definitions.keys.must_equal ["title", "id"]  }
  end
end
