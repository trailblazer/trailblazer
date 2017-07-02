require "test_helper"

class ContractExtractMacroTest < Minitest::Spec
  class Create < Trailblazer::Operation
    step Contract::Validate::Extract( key: "song", params_path: "x" )
  end

  it { Trailblazer::Operation::Inspect.(Create).must_equal %{[>x]} }
  it { Create.({}).inspect("x").must_equal %{<Result:false [nil] >} }
  it { Create.({ "song" => Object }).inspect("x").must_equal %{<Result:true [Object] >} }
end

class ContractTest < Minitest::Spec
  Song = Struct.new(:title)
#   # generic form for testing.
#   class Form
#     def initialize(model, options={})
#       @inspect = "#{self.class}: #{model} #{options.inspect}"
#     end

#     def validate
#       @inspect
#     end
#   end

#   # TODO: in all step tests.
#   describe "dependency injection" do
#     class Delete < Trailblazer::Operation
#       include Contract::Step
#     end

#     class Follow < Trailblazer::Operation
#       include Contract::Step
#     end

#     # inject contract instance via constructor.
#     it { Delete.({}, "contract" => "contract/instance")["contract"].must_equal "contract/instance" }
#     # inject contract class.
#     it { Follow.({}, "contract.default.class" => Form)["contract"].class.must_equal Form }
#   end


#   # contract(model, [admin: true]).validate
#   class Create < Trailblazer::Operation
#     include Test::ReturnProcess
#     include Contract::Explicit

#     def call(options:false)
#       return contract(model: Object, options: { admin: true }).validate if options
#       contract(model: Object).validate
#     end
#   end

#   # inject class, pass in model and options when constructing.
#   # contract(model)
#   it { Create.({}, "contract.default.class" => Form).must_equal "ContractTest::Form: Object {}" }
#   # contract(model, options)
#   it { Create.({ options: true }, "contract.default.class" => Form).must_equal "ContractTest::Form: Object {:admin=>true}" }

#   # ::contract Form
#   # contract(model).validate
#   class Update < Trailblazer::Operation
#     include Test::ReturnProcess
#     include Contract::Explicit

#      = Form

#     def call(*)
#       contract.validate
#     end

#     include Model( :Builder
# )    def model!(*)
#       Object
#     end
#   end

#   # use the class contract.
#   it { Update.().must_equal "ContractTest::Form: Object {}" }
#   # injected contract overrides class.
#   it { Update.({}, "contract.default.class" => Injected = Class.new(Form)).must_equal "ContractTest::Injected: Object {}" }

#   # passing Constant into #contract
#   # contract(Object.new, { title: "Bad Feeling" }, Contract)
#   class Operation < Trailblazer::Operation
#     include Contract::Explicit

#     class Contract < Reform::Form
#       property :title, virtual: true
#     end

#     def process(params)
#       contract(model: Object.new, options: { title: "Bad Feeling" }, contract_class: Contract)

#       validate(params)
#     end
#   end

#   # allow using #contract to inject model, options and class.
#   it do
#     contract = Operation.(id: 1)["contract"]
#     contract.title.must_equal "Bad Feeling"
#     contract.must_be_instance_of Operation::Contract
#   end

#   # allow using #contract before #validate.
#   class Upsert < Trailblazer::Operation
#     include Contract::Explicit

#     contract do
#       property :id
#       property :title
#       property :length
#     end

#     def process(params)
#       self["model"] = Struct.new(:id, :title, :length).new
#       contract.id = 1
#       validate(params) { contract.length = 3 }
#     end
#   end

#   it do
#     contract = Upsert.(title: "Beethoven")["contract"]
#     contract.id.must_equal 1
#     contract.title.must_equal "Beethoven"
#     contract.length.must_equal 3
#   end
# end

#---
#- validate
class ValidateTest < Minitest::Spec

  #---
  # Contract::Validate[]
  class Update < Trailblazer::Operation
    extend Contract::DSL
    contract do
      property :title
      validates :title, presence: true
    end

    step Model( Song, :new ) # FIXME.
    step Contract::Build()
    step Contract::Validate() # generic validate call for you.

    # include Procedural::Validate
    ->(*) { validate(options["params"][:song]) } # <-- TODO
  end

  # success
  it do
    result = Update.(title: "SVG")
    result.success?.must_equal true
    result["result.contract.default"].success?.must_equal true
    result["result.contract.default"].errors.messages.must_equal({})
  end

  # failure
  it do
    result = Update.(title: nil)
    result.success?.must_equal false
    result["result.contract.default"].success?.must_equal false
    result["result.contract.default"].errors.messages.must_equal({:title=>["can't be blank"]})
  end

  #---
  # Contract::Validate[key: :song]
  class Upsert < Trailblazer::Operation
    extend Contract::DSL
    contract do
      property :title
      validates :title, presence: true
    end

    step Model( Song, :new ) # FIXME.
    step Contract::Build()
    step Contract::Validate( key: :song) # generic validate call for you.
    # ->(*) { validate(options["params"][:song]) } # <-- TODO
    step Contract::Persist( method: :sync )
  end

  # success
  it { Upsert.(song: { title: "SVG" }).success?.must_equal true }
  # failure
  it { Upsert.(song: { title: nil }).success?.must_equal false }
  # key not found
  it { Upsert.().success?.must_equal false }

  #---
  # contract.default.params gets set (TODO: change in 2.1)
  it { Upsert.(song: { title: "SVG" })["params"].must_equal({:song=>{:title=>"SVG"}}) }
  it { Upsert.(song: { title: "SVG" })["contract.default.params"].must_equal({:title=>"SVG"}) }

  #---
  #- inheritance
  class New < Upsert
  end

  it { Trailblazer::Operation::Inspect.(New).must_equal %{[>model.build,>contract.build,>contract.default.validate,>persist.save]} }

  #- overwriting Validate
  class NewHit < Upsert
    step Contract::Validate( key: :hit ), override: true
  end

  it { Trailblazer::Operation::Inspect.(NewHit).must_equal %{[>model.build,>contract.build,>contract.default.validate,>persist.save]} }
  it { NewHit.(:hit => { title: "Hooray For Me" }).inspect("model").must_equal %{<Result:true [#<struct ContractTest::Song title=\"Hooray For Me\">] >} }
end

# #---
# # allow using #contract to inject model and arguments.
# class OperationContractWithOptionsTest < Minitest::Spec
#   # contract(model, title: "Bad Feeling")
#   class Operation < Trailblazer::Operation
#     include Contract::Explicit
#     contract do
#       property :id
#       property :title, virtual: true
#     end

#     def process(params)
#       model = Struct.new(:id).new

#       contract(model: model, options: { title: "Bad Feeling" })

#       validate(params)
#     end
#   end

#   it do
#     op = Operation.(id: 1)
#     op["contract"].id.must_equal 1
#     op["contract"].title.must_equal "Bad Feeling"
#   end

#   # contract({ song: song, album: album }, title: "Medicine Balls")
#   class CompositionOperation < Trailblazer::Operation
#     include Contract::Explicit
#     contract do
#       include Reform::Form::Composition
#       property :song_id,    on: :song
#       property :album_name, on: :album
#       property :title,      virtual: true
#     end

#     def process(params)
#       song  = Struct.new(:song_id).new(1)
#       album = Struct.new(:album_name).new("Forever Malcom Young")

#       contract(model: { song: song, album: album }, options: { title: "Medicine Balls" })

#       validate(params)
#     end
#   end

#   it do
#     contract = CompositionOperation.({})["contract"]
#     contract.song_id.must_equal 1
#     contract.album_name.must_equal "Forever Malcom Young"
#     contract.title.must_equal "Medicine Balls"
#   end

#   # validate(params, { song: song, album: album }, title: "Medicine Balls")
#   class CompositionValidateOperation < Trailblazer::Operation
#     include Contract::Explicit
#     contract do
#       include Reform::Form::Composition
#       property :song_id,    on: :song
#       property :album_name, on: :album
#       property :title,      virtual: true
#     end

#     def process(params)
#       song  = Struct.new(:song_id).new(1)
#       album = Struct.new(:album_name).new("Forever Malcom Young")

#       validate(params, model: { song: song, album: album }, options: { title: "Medicine Balls" })
#     end
#   end

#   it do
#     contract = CompositionValidateOperation.({})["contract"]
#     contract.song_id.must_equal 1
#     contract.album_name.must_equal "Forever Malcom Young"
#     contract.title.must_equal "Medicine Balls"
#   end
end

# TODO: full stack test with validate, process, save, etc.
          # with model!
