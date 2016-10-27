require "test_helper"
require "representable/json"
require "trailblazer/operation/representer"
require "trailblazer/operation/contract"

class DslRepresenterTest < MiniTest::Spec
  module SongProcess
    def process(params)
      self["model"] = OpenStruct.new(params)
    end

    def represented
      self["model"]
    end
  end

  describe "inheritance across operations" do
    class Operation < Trailblazer::Operation
      include Representer
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

  # name for representer
  describe "1) Op.representer :parse, Representer" do
    class Op1 < Trailblazer::Operation
      include Representer
      representer :parse, String
    end

    it { Op1["representer.parse.class"].superclass.must_equal String }
    it { Op1.({})["representer.parse.class"].superclass.must_equal String }
  end

  # name for default representer
  describe "2) Op.representer Representer" do
    class Op2 < Trailblazer::Operation
      include Representer
      representer String
      def call(*); self; end
    end

    it { Op2["representer.default.class"].superclass.must_equal String }
    it { Op2.({})["representer.default.class"].superclass.must_equal String }
    it { Op2.({}, "representer.default.class" => Integer)["representer.default.class"].must_equal Integer }
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
    class ContractOperation < Trailblazer::Operation
      include Representer
      include Representer::InferFromContract
      include SongProcess
      include Contract::Explicit

      contract do
        property :songTitle
      end
    end

    class ContractOperation2 < Trailblazer::Operation
      include Representer
      include SongProcess
      include Contract::Explicit
      include Representer::InferFromContract
      contract ContractOperation["contract.default.class"]

      representer do
        property :genre
      end
    end

    it { ContractOperation.("songTitle"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"songTitle":"Monsterparty"}} }
    # this representer block extends the inferred from contract.
    it { ContractOperation2.("songTitle"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"songTitle":"Monsterparty","genre":"Punk"}} }
  end

  describe "Op.representer_class" do
    class PlayRepresenter < Representable::Decorator
      include Representable::JSON
      property :title
    end

    class OpSettingRepresenter < Trailblazer::Operation
      include Representer
      include SongProcess
      self["representer.default.class"] = PlayRepresenter
    end

    class OpExtendRepresenter < Trailblazer::Operation
      include Representer
      include SongProcess
      self["representer.default.class"] = PlayRepresenter
      representer do
        property :genre
      end
    end

    # both operations produce the same as the representer is shared, not copied.
    it { skip; OpSettingRepresenter.("title"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"title":"Monsterparty","genre":"Punk"}} }
    it { OpExtendRepresenter.("title"=>"Monsterparty", "genre"=>"Punk").to_json.must_equal %{{"title":"Monsterparty","genre":"Punk"}} }
  end
end
