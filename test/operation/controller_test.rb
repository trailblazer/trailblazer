require "test_helper"
require "trailblazer/operation/controller"

class ControllerTest < Minitest::Spec
  User = Struct.new(:role)

  Comment = Struct.new(:body)

  class Comment::Update < Trailblazer::Operation
    def model!(params)
      Comment.new(params[:body])
    end

    def inspect
      super.sub(/:0x\w+/, "")
    end
  end

  class Controller
    include Trailblazer::Operation::Controller

    def initialize(params={})
      @params = params
    end
    attr_reader :params, :request

    def show
      present Comment::Update, params: { current_user: User.new(:admin) }
    end
  end

  describe "#present with options" do
    it do
      Controller.new.show.inspect.must_equal "#<ControllerTest::Comment::Update @options={}, @valid=true, @params={:current_user=>#<struct ControllerTest::User role=:admin>}, @model=#<struct ControllerTest::Comment body=nil>>"
    end
  end
end