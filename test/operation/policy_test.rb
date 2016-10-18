require "test_helper"
require "trailblazer/operation/policy"


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
    include Policy
    policy BlaPolicy, :create?

    def model!(*)
      Song.new
    end

    def call(*)
      self
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
    assert_raises Trailblazer::NotAuthorizedError do
      op = BlaOperation.({current_user: nil})
    end
  end


  # no policy set
  class NoPolicyOperation < Trailblazer::Operation
    include Policy
    # no policy.

    attr_reader :model

    def call(*)
      @model = Song.new
      self
    end

    class Delete < self
    end


    class LocalPolicy
      def initialize(user, song)
        @user = user
        @song = song
      end

      def update?; false end
    end

    class Update < self
      policy LocalPolicy, :update?
    end
  end

  # valid.
  it do
    op = NoPolicyOperation.({})
    op.model.must_be_instance_of Song
  end

  # inherited without config works.
  it do
    op = NoPolicyOperation::Delete.({})
    op.model.must_be_instance_of Song
  end

  # inherited can override.
  it do
    assert_raises Trailblazer::NotAuthorizedError do
      op = NoPolicyOperation::Update.({})
    end
  end
end
