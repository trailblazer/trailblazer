require "test_helper"
require "trailblazer/operation/controller"

class ControllerTest < Minitest::Spec
  def self.controller!(&block)
    let (:_controller) {
      Class.new do
        include Trailblazer::Operation::Controller

        def initialize(params={})
          @params = params
        end
        attr_reader :params, :request

        class_eval(&block)
        self
      end
    }
  end

  def controller(params={})
    _controller.new(params)
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

  describe "#form" do
    class Comment::Create < Trailblazer::Operation
      def model!(params)
        Comment.new
      end

      contract do
        def prepopulate!(options)
          @options = options
        end
        attr_reader :options
      end
    end

    describe "#prepopulate! options" do
      controller! do
        def show
          form Comment::Create
        end
      end

      it { controller(__body: "Great!").show.options.inspect.must_equal "{:params=>{:__body=>\"Great!\"}}" }
    end

    describe "with additional options" do
      controller! do
        def show
          form Comment::Create, admin: true
        end
      end

      it { controller(__body: "Great!").show.options.inspect.must_equal "{:admin=>true, :params=>{:__body=>\"Great!\"}}" }
    end

    describe "with options and :params" do
      controller! do
        def show
          form Comment::Create, admin: true, params: params.merge(user: User.new)
        end
      end

      it { controller(__body: "Great!").show.options.inspect.must_equal "{:admin=>true, :params=>{:__body=>\"Great!\", :user=>#<struct ControllerTest::User role=nil>}}" }
    end
  end
end