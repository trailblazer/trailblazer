require "test_helper"
require "dry/container"
require "trailblazer/operation/auto_inject"

class DryAutoInjectTest < Minitest::Spec
  my_container = Dry::Container.new
  my_container.register(:user_repository, -> { Object })

  AutoInject = Trailblazer::Operation::AutoInject(my_container)

  class Create < Trailblazer::Operation
    include AutoInject[:user_repository]
  end

  it "auto-injects user_repository" do
    res = Create.({})
    res[:user_repository].must_equal Object
  end

  it "allows dependency injection via ::call" do
    Create.({}, user_repository: String)[:user_repository].must_equal String
  end

  describe "inheritance" do
    class Update < Create
    end

    it { Update.()[:user_repository].must_equal Object }
  end
end
