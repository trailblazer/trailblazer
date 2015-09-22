require "test_helper"

# ::contract builds Reform::Form class
class DslContractTest < MiniTest::Spec
  module SongProcess
    def process(params)
      validate(params, @model = OpenStruct.new)
    end
  end

  describe "inheritance across operations" do
    # inheritance
    class Operation < Trailblazer::Operation
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
    end

    # inherits subclassed Contract.
    it { Operation.contract_class.wont_equal Operation::JSON.contract_class }

    it do
      form = Operation.contract_class.new(OpenStruct.new)
      form.validate({})#.must_equal true
      form.errors.to_s.must_equal "{}"

      form = Operation::JSON.contract_class.new(OpenStruct.new)
      form.validate({})#.must_equal true
      form.errors.to_s.must_equal "{:genre=>[\"can't be blank\"]}"
    end

    # allows overriding options
    it do
      form = Operation::JSON.contract_class.new(song = OpenStruct.new)
      form.validate({genre: "Punkrock", band: "Osker"}).must_equal true
      form.sync

      song.genre.must_equal "Punkrock"
      song.band.must_equal nil
    end
  end

  describe "Op.contract" do
    it { Operation.contract.must_equal Operation.contract_class }
  end

  describe "Op.contract CommentForm" do
    class SongForm < Reform::Form
      property :songTitle, validates: {presence: true}
    end

    class OpWithExternalContract < Trailblazer::Operation
      contract SongForm
      include SongProcess
    end

    it { OpWithExternalContract.("songTitle"=> "Monsterparty").contract.songTitle.must_equal "Monsterparty" }
  end

  describe "Op.contract CommentForm do .. end" do
    class DifferentSongForm < Reform::Form
      property :songTitle, validates: {presence: true}
    end

    class OpNotExtendingContract < Trailblazer::Operation
      contract DifferentSongForm
      include SongProcess
    end

    class OpExtendingContract < Trailblazer::Operation
      contract DifferentSongForm do
        property :genre
      end
      include SongProcess
    end

    # this operation copies DifferentSongForm and shouldn't have `genre`.
    it do
      contract = OpNotExtendingContract.("songTitle"=>"Monsterparty", "genre"=>"Punk").contract
      contract.songTitle.must_equal "Monsterparty"
      assert_raises(NoMethodError) { contract.genre }
    end

    # this operation copies DifferentSongForm and extends it with the property `genre`.
    it do
      contract = OpExtendingContract.("songTitle"=>"Monsterparty", "genre"=>"Punk").contract
      contract.songTitle.must_equal "Monsterparty"
      contract.genre.must_equal "Punk"
    end

    # of course, the original contract wasn't modified, either.
    it do
      assert_raises(NoMethodError) { DifferentSongForm.new(OpenStruct.new).genre }
    end
  end
end