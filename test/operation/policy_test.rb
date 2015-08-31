require "test_helper"
require "trailblazer/operation/policy"

class OpPolicyTest < MiniTest::Spec
  Song = Struct.new(:name)

  class Create < Trailblazer::Operation
    include Policy

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
      include Policy

      def process(*)
      end
    end

    it { Show.({}).wont_equal nil }
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



class OpPunditPolicyTest < MiniTest::Spec
  Song = Struct.new(:name)
  User = Struct.new(:name)

  class BlaPolicy
    def initialize(user, song)
      @user = user
      @song = song
    end

    def create?
      @user.is_a?(User) and @song.is_a?(Song)
    end

    def edit?
      "yepp"
    end
  end

  class BlaOperation < Trailblazer::Operation
    include Policy::Pundit
    policy BlaPolicy, :create?

    def model!(*)
      Song.new
    end

    def process(*)
    end
  end

  # valid.
  it do
    op = BlaOperation.({current_user: User.new})

    # #policy provides the Policy instance.
    op.policy.edit?.must_equal "yepp"
  end

  # invalid.
  it do
    assert_raises Pundit::NotAuthorizedError do
      op = BlaOperation.({current_user: nil})
    end
  end


  # no policy set
  class NoPolicyOperation < Trailblazer::Operation
    include Policy::Pundit
    # no policy.

    def process(*)
      @model = Song.new
    end
  end

  # valid.
  it do
    op = NoPolicyOperation.({})
    op.model.must_be_instance_of Song
  end
end