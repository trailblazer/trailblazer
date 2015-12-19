require "test_helper"
require "trailblazer/operation/controller"

class ControllerTest < Minitest::Spec
  def self.controller!(&block)
    let (:controller) {
      Class.new do
        include Trailblazer::Operation::Controller

        def initialize(params={})
          @params = params
        end
        attr_reader :params, :request
        class_eval(&block)
        self
      end.new
    }
  end


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


  describe "#present with options" do
    controller! do
      def show
        present Comment::Update, params: { current_user: User.new(:admin) }
      end
    end

    it do
      controller.show.inspect.must_equal "#<ControllerTest::Comment::Update @options={}, @valid=true, @params={:current_user=>#<struct ControllerTest::User role=:admin>}, @model=#<struct ControllerTest::Comment body=nil>>"
    end
  end

  describe "#params!" do
    controller! do
      def show
        present Comment::Update, params: "Cool!"
      end

      def params!(params)
        { body: params }
      end
    end

    it { controller.show.inspect.must_equal "#<ControllerTest::Comment::Update @options={}, @valid=true, @params={:body=>\"Cool!\"}, @model=#<struct ControllerTest::Comment body=\"Cool!\">>" }
  end
end