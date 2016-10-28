require "test_helper"
require "trailblazer/operation/contract"

      require "dry/validation"

class DryValidationTest < Minitest::Spec
  class Create < Trailblazer::Operation
    extend Contract::DSL

    contract "params", (Dry::Validation.Schema do
      required(:id).filled
    end)
    # self["contract.params"] = Dry::Validation.Schema do
    #   required(:id).filled
    # end

    include Contract::Validate
    def process(params)
      validate(params, contract: self["contract.params"], path: "contract.params") { |f| puts f.inspect }
    end
  end

  it { Create.(id: 1) }
end

class ContractTest < Minitest::Spec
  # generic form for testing.
  class Form
    def initialize(model, options={})
      @inspect = "#{self.class}: #{model} #{options.inspect}"
    end

    def validate
      @inspect
    end
  end

  # contract do..end (without constant)
  describe "contract do .. end" do
    class Index < Trailblazer::Operation
      include Contract::Step
      contract do
        property :title
      end

      include Model::Builder
      def model!(*); Struct.new(:title).new; end

      def call(params)
        validate(params) { |f| return f.to_nested_hash }
      end
    end

    # will create a Reform::Form for us.
    it { Index.(title: "Falling Down").must_equal({"title"=>"Falling Down"}) }
  end

  # TODO: in all step tests.
  describe "dependency injection" do
    class Delete < Trailblazer::Operation
      include Contract::Step
    end

    class Follow < Trailblazer::Operation
      include Contract::Step
    end

    # inject contract instance via constructor.
    it { Delete.({}, "contract" => "contract/instance")["contract"].must_equal "contract/instance" }
    # inject contract class.
    it { Follow.({}, "contract.default.class" => Form)["contract"].class.must_equal Form }
  end


  # contract(model, [admin: true]).validate
  class Create < Trailblazer::Operation
    include Contract::Explicit

    def call(options:false)
      return contract(model: Object, options: { admin: true }).validate if options
      contract(model: Object).validate
    end
  end

  # inject class, pass in model and options when constructing.
  # contract(model)
  it { Create.({}, "contract.default.class" => Form).must_equal "ContractTest::Form: Object {}" }
  # contract(model, options)
  it { Create.({ options: true }, "contract.default.class" => Form).must_equal "ContractTest::Form: Object {:admin=>true}" }

  # ::contract Form
  # contract(model).validate
  class Update < Trailblazer::Operation
    include Contract::Explicit

    self["contract.default.class"] = Form

    def call(*)
      contract.validate
    end

    include Model::Builder
    def model!(*)
      Object
    end
  end

  # use the class contract.
  it { Update.().must_equal "ContractTest::Form: Object {}" }
  # injected contract overrides class.
  it { Update.({}, "contract.default.class" => Injected = Class.new(Form)).must_equal "ContractTest::Injected: Object {}" }

  # passing Constant into #contract
  # contract(Object.new, { title: "Bad Feeling" }, Contract)
  class Operation < Trailblazer::Operation
    include Contract::Explicit

    class Contract < Reform::Form
      property :title, virtual: true
    end

    def process(params)
      contract(model: Object.new, options: { title: "Bad Feeling" }, contract_class: Contract)

      validate(params)
    end
  end

  # allow using #contract to inject model, options and class.
  it do
    contract = Operation.(id: 1)["contract"]
    contract.title.must_equal "Bad Feeling"
    contract.must_be_instance_of Operation::Contract
  end

  # allow using #contract before #validate.
  class Upsert < Trailblazer::Operation
    include Contract::Explicit

    contract do
      property :id
      property :title
      property :length
    end

    def process(params)
      self["model"] = Struct.new(:id, :title, :length).new
      contract.id = 1
      validate(params) { contract.length = 3 }
    end
  end

  it do
    contract = Upsert.(title: "Beethoven")["contract"]
    contract.id.must_equal 1
    contract.title.must_equal "Beethoven"
    contract.length.must_equal 3
  end
end

class ValidateTest < Minitest::Spec
  class Form
    class Result
      def initialize(bool); @bool = bool end
      def success?; @bool end
      def errors; ["404"] end
    end
    def initialize(*); end
    # def validate(result); result; end
    def call(params); Result.new(params); end
  end

  class Create < Trailblazer::Operation
    include Contract::Explicit
    contract Form

    def call(params)
      if validate(params[:valid])
        "works!"
      else
        "try again"
      end
    end

    def model
    end
  end

  # validate returns the #validate result by building contract using #contract.
  it { Create.(valid: false).must_equal "try again" }
  it { Create.(valid: true).must_equal "works!" }
end

#---
# allow using #contract to inject model and arguments.
class OperationContractWithOptionsTest < Minitest::Spec
  # contract(model, title: "Bad Feeling")
  class Operation < Trailblazer::Operation
    include Contract::Explicit
    contract do
      property :id
      property :title, virtual: true
    end

    def process(params)
      model = Struct.new(:id).new

      contract(model: model, options: { title: "Bad Feeling" })

      validate(params)
    end
  end

  it do
    op = Operation.(id: 1)
    op.contract.id.must_equal 1
    op.contract.title.must_equal "Bad Feeling"
  end

  # contract({ song: song, album: album }, title: "Medicine Balls")
  class CompositionOperation < Trailblazer::Operation
    include Contract::Explicit
    contract do
      include Reform::Form::Composition
      property :song_id,    on: :song
      property :album_name, on: :album
      property :title,      virtual: true
    end

    def process(params)
      song  = Struct.new(:song_id).new(1)
      album = Struct.new(:album_name).new("Forever Malcom Young")

      contract(model: { song: song, album: album }, options: { title: "Medicine Balls" })

      validate(params)
    end
  end

  it do
    contract = CompositionOperation.({})["contract"]
    contract.song_id.must_equal 1
    contract.album_name.must_equal "Forever Malcom Young"
    contract.title.must_equal "Medicine Balls"
  end

  # validate(params, { song: song, album: album }, title: "Medicine Balls")
  class CompositionValidateOperation < Trailblazer::Operation
    include Contract::Explicit
    contract do
      include Reform::Form::Composition
      property :song_id,    on: :song
      property :album_name, on: :album
      property :title,      virtual: true
    end

    def process(params)
      song  = Struct.new(:song_id).new(1)
      album = Struct.new(:album_name).new("Forever Malcom Young")

      validate(params, model: { song: song, album: album }, options: { title: "Medicine Balls" })
    end
  end

  it do
    contract = CompositionValidateOperation.({})["contract"]
    contract.song_id.must_equal 1
    contract.album_name.must_equal "Forever Malcom Young"
    contract.title.must_equal "Medicine Balls"
  end
end

# TODO: full stack test with validate, process, save, etc.
          # with model!
