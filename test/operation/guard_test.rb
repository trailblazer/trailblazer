require "test_helper"
require "trailblazer/operation/policy"

class OpPolicyGuardTest < MiniTest::Spec
  Song = Struct.new(:name)

  class Create < Trailblazer::Operation
    include Policy::Guard

    def model!(*)
      Song.new
    end

    policy do |params|
      model.is_a?(Song) and params[:valid]
    end

    def process(*)
    end
  end

  # valid.
  it do
    op = Create.(valid: true)
  end

  # invalid.
  it do
    assert_raises Trailblazer::NotAuthorizedError do
      op = Create.(valid: false)
    end
  end


  describe "inheritance" do
    class Update < Create
      policy do |params|
        params[:valid] == "correct"
      end
    end

    class Delete < Create
    end

    it do
      Create.(valid: true).wont_equal nil
      Delete.(valid: true).wont_equal nil
      Update.(valid: "correct").wont_equal nil
    end
  end


  describe "no policy defined, but included" do
    class Show < Trailblazer::Operation
      include Policy::Guard

      def process(*)
      end
    end

    it { Show.({}).wont_equal nil }
  end


  describe "#params!" do
    class Index < Trailblazer::Operation
      include Policy::Guard

      # make sure the guard receives the correct params.
      policy { |params| params[:valid] == "true" }

      def params!(params)
        { valid: params }
      end

      def process(*)
      end
    end

    it { Index.("true").wont_equal nil }
    it { assert_raises(Trailblazer::NotAuthorizedError) { Index.(false).wont_equal nil } }
  end
end

class OpBuilderDenyTest < MiniTest::Spec
  Song = Struct.new(:name)

  class Create < Trailblazer::Operation
    include Deny

    builds do |params|
      deny! unless params[:valid]
    end

    def process(params)
    end
  end

  class Update < Create
    builds -> (params) do
      deny! unless params[:valid]
    end
  end

  # valid.
  it do
    op = Create.(valid: true)
  end

  # invalid.
  it do
    assert_raises Trailblazer::NotAuthorizedError do
      op = Create.(valid: false)
    end
  end
end
