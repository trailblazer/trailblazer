require "test_helper"
require "pipetree"

BuildOperation = ->(klass, options) { klass.build_operation(options[:params], options[:skills]) } # returns operation instance.
Call           = ->(operation, options) { operation.call(options[:params]) }                      # returns #call result.

module Trailblazer::Operation::Pipetree
  def call(params={}, options={})
    pipe = self["pipetree"] # TODO: injectable? WTF? how cool is that?


    result = {}
    skills = Trailblazer::Skill.new(result, options, self.skills) # FIXME: redundant from Op::Skill.

    outcome = pipe.(self, { skills: skills, params: params }) # (class, { skills: , params: })

    outcome == ::Pipetree::Stop ? result : outcome # THIS SUCKS a bit.

    # FIXME: simply return op?
  end
end

class PipetreeTest < Minitest::Spec

  #--- injected option is available in class-level function.
  it do
    Class.new(Trailblazer::Operation) do
      extend Trailblazer::Operation::Pipetree
      self["pipetree"] = ::Pipetree[
        ->(input, options) { options[:skills]["user.current"] } # read user.current which we're injecting into ::call.
      ]
    end.
      ({}, "user.current" => Object).must_equal Object
  end





  module Setup
    # Params ->(result, options) { snippet }
    # Model ->(result, options) { snippet }
  end

  Song = Struct.new(:title)
# the idea is, leave the configuration in the operation. the implementation can be done on the op, or in a dedicated object that *reads* config from the op.

  class Auth
    def initialize(*args); @user, @model = *args end
    def create?; @user == Module end
    def inspect; "<Auth: user:#{@user.inspect}, model:#{@model.inspect}>" end
  end


  class Create < Trailblazer::Operation
    extend Declarative::Heritage::Inherited
        extend Declarative::Heritage::DSL
    extend Model::DSL
    model Song, :create

    require "trailblazer/operation/policy"
    extend Policy::DSL
    policy Auth, :create?

    extend Pipetree

    def call(params)
      self
    end

    def process(params)
      # validate(params)
      #   success
      #     callbacks
    end

    # unwrap params.
    SetupParams = ->(input, options) { options[:params][:song]; input }

    # the only problem here is, that people accidentially might write to `input` on a class level.

    ModelBuilderBuilder = ->(input, options) { options[:model] = ModelBuilder.new(options[:skills]).(options[:params]); input }
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

    AssignModel = ->(input, options) { options[:skills]["model"]   = options[:model]; input }
    AssignPolicy = ->(input, options) { options[:skills]["policy"] = options[:policy]; input }


    # "current_user" is now a skill dependency, not a params option anymore.
    PolicyEvaluate = ->(input, options) {
      # raise options[:skills]["model"].inspect
      options[:policy] = options[:skills]["policy.evaluator"].(options[:skills]["user.current"], options[:skills]["model"]) { # DISCUSS: where do we get the model from? [:write]["model"] or [:model]
        options[:skills][:valid] = false
        options[:skills]["policy.message"] = "Not allowed"

        return ::Pipetree::Stop }; input
    }

    self["pipetree"] = ::Pipetree[
      BuildOperation,
      SetupParams,
      ModelBuilderBuilder, AssignModel,
      PolicyEvaluate,
      AssignPolicy,
      Call,
    ]
  end

  #--- Operation#call overridden
  # successful policy
  it do
    res = Create.({song: { title: "311" }}, "user.current" => Module)
    res["model"].to_s.must_equal %{#<struct PipetreeTest::Song title=nil>}
    res["policy"].inspect.must_equal %{<Auth: user:Module, model:#<struct PipetreeTest::Song title=nil>>}
    # injection via initializer works.
    res["user.current"].must_equal Module
  end
  # policy breach
  it do
    res = Create.({song: { title: "311" }}, "user.current" => nil)
    res.inspect.must_equal %{{"model"=>#<struct PipetreeTest::Song title=nil>, :valid=>false, "policy.message"=>"Not allowed"}}
  end

  #---
  # External and Resolver, done right.
  class Update < Trailblazer::Operation
    extend Declarative::Heritage::Inherited
        extend Declarative::Heritage::DSL

    extend Model::DSL
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
    op["policy"].inspect.must_equal %{<Auth: user:Module, model:#<struct PipetreeTest::Song title=nil>>}
    op["model"].class.must_equal Song
  }

  # policy breach.
  it do
    res = Update.({}, "user.current" => Class)

    res.inspect.must_equal %{{"model"=>#<struct PipetreeTest::Song title=nil>, :valid=>false, "policy.message"=>"Not allowed"}}

    # make sure policy class is correct, and user and model are set.
    # res["policy"].inspect.must_match /Auth:.+? @user=Module, @model=#<struct PipetreeTest::Song title=nil>/
    # res["model"].class.must_equal Song
  end
end
