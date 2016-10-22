require "test_helper"
require "pipetree"

BuildOperation = ->(params, options) { options[:operation] = options[:class].build_operation(params, options[:write]); params }
Call           = ->(params, options) { options[:operation].call(params) }

module Trailblazer::Operation::Pipetree
  def call(params={}, options={})
    # FIXME: other skills from other containers are not available here.

    pipe = self["pipetree"] # TODO: injectable? WTF? how cool is that?


    result = {}

    outcome = pipe.(params, { read: self, write: options=options.dup, result: result, class: self })

    outcome == ::Pipetree::Stop ? result : outcome # THIS SUCKS a bit.
  end
end

class PipetreeTest < Minitest::Spec
  module Setup
    # Params ->(result, options) { snippet }
    # Model ->(result, options) { snippet }
  end

  Song = Struct.new(:title)
# the idea is, leave the configuration in the operation. the implementation can be done on the op, or in a dedicated object that *reads* config from the op.

  class Auth
    def initialize(*args)
      @user, @model = *args
    end

    def create?
      @user == Module
    end
  end


  class Create < Trailblazer::Operation
    include Model
    model Song, :create

    require "trailblazer/operation/policy"
    extend Policy::DSL
    policy Auth, :create?

    extend Pipetree

    def call(params)
    #   super
      self["model"]
    end

    def process(params)
      # validate(params)
      #   success
      #     callbacks
    end

    # unwrap params.
    SetupParams = ->(input, options) { input[:song] }



    ModelBuilderBuilder = ->(input, options) { options[:model] = ModelBuilder.new(options[:read]).(input); input }
    # this is to be able to use BuildModel. i really don't know if we actually need to do that.
    # what if people want to override #model! for example?
    class ModelBuilder
      def initialize(skills)
        @delegator = skills
      end

      extend Uber::Delegates
      delegates :@delegator, :[]=, :[]

      include Trailblazer::Operation::Model::BuildModel # #instantiate_model and so on.

      def call(params)
        model!(params)
      end
    end

    AssignModel = ->(input, options) { options[:write]["model"]   = options[:model] }
    AssignPolicy = ->(input, options) { options[:write]["policy"] = options[:policy] }


    # "current_user" is now a skill dependency, not a params option anymore.
    PolicyEvaluate = ->(input, options) {
      # TODO: assign policy
      options[:policy] = options[:read]["policy.evaluator"].(options[:write]["user.current"], options[:model]) { # DISCUSS: where do we get the model from? [:write]["model"] or [:model]
        options[:result][:valid] = false
        options[:result]["policy.message"] = "Not allowed"

        return ::Pipetree::Stop }; input
    }

    self["pipetree"] = ::Pipetree[
      BuildOperation,
      SetupParams,
      ModelBuilderBuilder, AssignModel,
      PolicyEvaluate,
      Call,
    ]


  end

  it { Create.({song: { title: "311" }}, "user.current" => Module).class.must_equal Song }

  #---
  # External and Resolver, done right.


  class Update < Trailblazer::Operation
    include Model
    extend Policy::DSL

    model Song
    policy Auth, :create?

    # include Pipetree
    self["pipetree"] = ::Pipetree[
        Create::SetupParams,
        Create::ModelBuilderBuilder, Create::AssignModel,
        Create::PolicyEvaluate, Create::AssignPolicy,
        BuildOperation,
        Call,
      ]

    extend Pipetree

    def call(*)
      self
    end
  end

  # successful policy.
  it {#<struct PipetreeTest::Song title=nil>
    op = Update.({}, "user.current" => Module)

    # make sure policy class is correct, and user and model are set.
    op["policy"].inspect.must_match /Auth:.+? @user=Module, @model=#<struct PipetreeTest::Song title=nil>/
    op["model"].class.must_equal Song
  }

  # policy breach.
  it do
    res = Update.({}, "user.current" => Class)

    res.inspect.must_equal %{{:valid=>false, "policy.message"=>"Not allowed"}}

    # make sure policy class is correct, and user and model are set.
    # res["policy"].inspect.must_match /Auth:.+? @user=Module, @model=#<struct PipetreeTest::Song title=nil>/
    # res["model"].class.must_equal Song
  end
end
