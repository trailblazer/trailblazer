require "test_helper"
require "trailblazer/operation/resolver"

class ResolverTest < MiniTest::Spec
  Song = Struct.new(:title)
  User = Struct.new(:name)

  class MyKitchenRules
    def initialize(user, song)
      @user = user
      @song = song
    end

    def create?
      @user.is_a?(User) and @song.is_a?(Song)
    end

    def admin?
      @user && @user.name == "admin" && @song.is_a?(Song)
    end

    def true?
      true
    end
  end

  class Create < Trailblazer::Operation
    include Resolver
    model Song, :create
    policy MyKitchenRules, :create?

    builds-> (model, policy, params) do
      return ForGaryMoore if model.title == "Friday On My Mind"
      return Admin if policy.admin?
      return SignedIn if params[:current_user] && params[:current_user].name
    end

    def self.model!(params)
      Song.new(params[:title])
    end

    def process(*)
    end

    class Admin < self
    end
    class SignedIn < self
    end
  end

   # valid.
  it { Create.({current_user: User.new}).must_be_instance_of Create }
  it { Create.({current_user: User.new("admin")}).must_be_instance_of Create::Admin }
  it { Create.({current_user: User.new("kenneth")}).must_be_instance_of Create::SignedIn }

  # invalid.
  it do
    assert_raises Trailblazer::NotAuthorizedError do
      Create.({})
    end
  end


  describe "passes policy into operation" do
    class Update < Trailblazer::Operation
      include Resolver
      model Song, :create
      policy MyKitchenRules, :true?

      builds-> (model, policy, params) do
        policy.instance_eval { def whoami; "me!" end }
        nil
      end

      def process(*)
      end
    end

    it do
      Update.({}).policy.whoami.must_equal "me!"
    end
  end
end