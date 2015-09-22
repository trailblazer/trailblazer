require "test_helper"
require "representable/json"
require "trailblazer/operation/representer"
require "trailblazer/operation/responder"

class DslRepresenterTest < MiniTest::Spec
  module SongProcess
    def process(params)
      @model = OpenStruct.new(params)
    end

    def represented
      model
    end
  end

  describe "inheritance across operations" do
    class Operation < Trailblazer::Operation
      include Representer
      include Responder
      include SongProcess

      representer do
        property :title
      end

      class JSON < self
        representer do
          property :band
        end
      end
    end

    it { Operation.(title: "Nothing To Lose", band: "Gary Moore").to_json.must_equal %{{"title":"Nothing To Lose"}} }
    # only the subclass must have the `band` field, even though it's set in the original operation.
    it { Operation::JSON.(title: "Nothing To Lose", band: "Gary Moore").to_json.must_equal %{{"title":"Nothing To Lose","band":"Gary Moore"}} }
  end

  describe "Op.representer" do
    it { Operation.representer.must_equal Operation.representer_class }
  end

  describe "Op.representer CommentRepresenter" do
    class SongRepresenter < Representable::Decorator
      include Representable::JSON
      property :songTitle
    end

    class OpWithExternalRepresenter < Trailblazer::Operation
      include Representer
      include SongProcess
      representer SongRepresenter
    end

    it { OpWithExternalRepresenter.("songTitle"=>"Listen To Your Heartbeat").to_json.must_equal %{{"songTitle":"Listen To Your Heartbeat"}} }
  end

  describe "Op.representer CommentRepresenter do .. end" do
    class HitRepresenter < Representable::Decorator
      include Representable::JSON
      property :title
    end

    class OpNotExtendingRepresenter < Trailblazer::Operation
      include Representer
      include SongProcess
      representer HitRepresenter
    end

    class OpExtendingRepresenter < Trailblazer::Operation
      include Representer
      include SongProcess
      representer HitRepresenter do
        property :genre
      end
    end

    # this operation copies HitRepresenter and shouldn't have `genre`.
    it do
      OpNotExtendingRepresenter.("title"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"title":"Monsterparty"}}
    end

    # # this operation copies HitRepresenter and extends it with the property `genre`.
    it do
      OpExtendingRepresenter.("title"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"title":"Monsterparty","genre":"Punk"}}
    end

    # # of course, the original representer wasn't modified, either.
    it do
      HitRepresenter.new(OpenStruct.new(title: "Monsterparty", genre: "Punk")).to_json.must_equal %{{"title":"Monsterparty"}}
    end
  end

  describe "Op.representer (inferring)" do
    class OpWithContract < Trailblazer::Operation
      include Representer
      include SongProcess

      contract do
        property :songTitle
      end
    end

    class OpWithContract2 < Trailblazer::Operation
      include Representer
      include SongProcess

      contract OpWithContract.contract
      representer do
        property :genre
      end
    end

    it { OpWithContract.("songTitle"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"songTitle":"Monsterparty"}} }
    it { OpWithContract2.("songTitle"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"songTitle":"Monsterparty","genre":"Punk"}} }
  end

  describe "Op.representer_class" do
    class PlayRepresenter < Representable::Decorator
      include Representable::JSON
      property :title
    end

    class OpSettingRepresenter < Trailblazer::Operation
      include Representer
      include SongProcess
      self.representer_class= PlayRepresenter
    end

    class OpExtendRepresenter < Trailblazer::Operation
      include Representer
      include SongProcess
      self.representer_class= PlayRepresenter
      representer do
        property :genre
      end
    end

    # both operations produce the same as the representer is shared, not copied.
    it { OpSettingRepresenter.("title"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"title":"Monsterparty","genre":"Punk"}} }
    it { OpExtendRepresenter.("title"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"title":"Monsterparty","genre":"Punk"}} }
  end
end