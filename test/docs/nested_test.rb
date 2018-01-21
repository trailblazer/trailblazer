require "test_helper"

class DocsNestedOperationTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find(id)
      return new(1, "Bristol") if id == 1
    end
  end

  #---
  #- nested operations
  #:edit
  class Edit < Trailblazer::Operation
    extend ClassDependencies
    extend Contract::DSL

    contract do
      property :title
    end

    step Model( Song, :find )
    step Contract::Build()
  end
  #:edit end

    # step Nested( Edit ) #, "policy.default" => self["policy.create"]
  #:update
  class Update < Trailblazer::Operation
    step Nested( Edit )
    # step ->(options, **) { puts options.keys.inspect }
    step Contract::Validate()

    step Contract::Persist( method: :sync )
  end
  #:update end

  # puts Update["pipetree"].inspect(style: :rows)

  #-
  # Edit allows grabbing model and contract
  it do
  #:edit-call
  result = Edit.(params: {id: 1})

  result[:model]            #=> #<Song id=1, title=\"Bristol\">
  result["contract.default"] #=> #<Reform::Form ..>
  #:edit-call end
    result.inspect(:model).must_equal %{<Result:true [#<struct DocsNestedOperationTest::Song id=1, title=\"Bristol\">] >}
    result["contract.default"].model.must_equal result[:model]
  end

#- test Edit circuit-level.
it do
  signal, (result, _) = Edit.__call__( [Trailblazer::Context( params: {id: 1} ), {}] )
  result[:model].inspect.must_equal %{#<struct DocsNestedOperationTest::Song id=1, title=\"Bristol\">}
end

  #-
  # Update also allows grabbing Edit/model and Edit/contract
  it do
  #:update-call
  result = Update.(params: {id: 1, title: "Call It A Night"})

  result[:model]            #=> #<Song id=1 , title=\"Call It A Night\">
  result["contract.default"] #=> #<Reform::Form ..>
  #:update-call end
    result.inspect(:model).must_equal %{<Result:true [#<struct DocsNestedOperationTest::Song id=1, title=\"Call It A Night\">] >}
    result["contract.default"].model.must_equal result[:model]
  end

  #-
  # Edit is successful.
  it do
    result = Update.(params: { id: 1, title: "Miami" }, current_user: Module)
    result.inspect(:model).must_equal %{<Result:true [#<struct DocsNestedOperationTest::Song id=1, title="Miami">] >}
  end

  # Edit fails
  it do
    Update.(params: {id: 2}).inspect(:model).must_equal %{<Result:false [nil] >}
  end
end

class NestedInput < Minitest::Spec
  #:input-multiply
  class Multiplier < Trailblazer::Operation
    step ->(options, x:, y:, **) { options["product"] = x*y }
  end
  #:input-multiply end

  #:input-pi
  class MultiplyByPi < Trailblazer::Operation
    step ->(options, **) { options["pi_constant"] = 3.14159 }
    step Nested( Multiplier, input: ->(options, **) do
      { "y" => options["pi_constant"],
        "x" => options["x"]
      }
    end )
  end
  #:input-pi end

  it { MultiplyByPi.("x" => 9).inspect("product").must_equal %{<Result:true [28.27431] >} }

  it do
    #:input-result
    result = MultiplyByPi.("x" => 9)
    result["product"] #=> [28.27431]
    #:input-result end
  end
end

class NestedInputCallable < Minitest::Spec
  Multiplier = NestedInput::Multiplier

  #:input-callable
  class MyInput
    def self.call(options, **)
      {
        "y" => options["pi_constant"],
        "x" => options["x"]
      }
    end
  end
  #:input-callable end

  #:input-callable-op
  class MultiplyByPi < Trailblazer::Operation
    step ->(options, **) { options["pi_constant"] = 3.14159 }
    step Nested( Multiplier, input: MyInput )
  end
  #:input-callable-op end

  it { MultiplyByPi.("x" => 9).inspect("product").must_equal %{<Result:true [28.27431] >} }
end

#---
#- Nested( .., output: )
class NestedOutput < Minitest::Spec
  Edit = DocsNestedOperationTest::Edit

  #:output
  class Update < Trailblazer::Operation
    step Nested( Edit, output: ->( ctx, ** ) do
      {
        "contract.my" => ctx["contract.default"],
        model:           ctx[:model]
      }
    end )
    step Contract::Validate( name: "my" )
    step Contract::Persist( method: :sync, name: "my" )
  end
  #:output end

  it { Update.( params: {id: 1, title: "Call It A Night"} ).inspect(:model, "contract.default").
      must_equal %{<Result:true [#<struct DocsNestedOperationTest::Song id=1, title=\"Call It A Night\">, nil] >} }

  it do
    result = Update.( params: {id: 1, title: "Call It A Night"} )

    result[:model]            #=> #<Song id=1 , title=\"Call It A Night\">
  end
end

#---
# Nested( ->{} )
class NestedWithCallableTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  module Song::Contract
    class Create < Reform::Form
      property :title
    end
  end

  User = Struct.new(:is_admin) do
    def admin?
      !! is_admin
    end
  end

  class Create < Trailblazer::Operation
    step Nested( ->(options, current_user:nil, **) { current_user.admin? ? Admin : NeedsModeration })

    class NeedsModeration < Trailblazer::Operation
      step Model( Song, :new )
      step Contract::Build( constant: Song::Contract::Create )
      step Contract::Validate()
      step :notify_moderator!

      def notify_moderator!(options, **)
        #~noti
        options["x"] = true
        #~noti end
      end
    end

    class Admin < Trailblazer::Operation # TODO: test if current_user is passed in.

    end
  end

  let (:admin) { User.new(true) }
  let (:anonymous) { User.new(false) }

  it { Create.(params: {}, current_user: anonymous).inspect("x").must_equal %{<Result:true [true] >} }
  it { Create.(params: {}, current_user: admin)    .inspect("x").must_equal %{<Result:true [nil] >} }

  #---
  #:method
  class Update < Trailblazer::Operation
    step Nested( :build! )

    def build!(options, current_user:nil, **)
        current_user.admin? ? Create::Admin : Create::NeedsModeration
    end
  end
  #:method end

  it { Update.(params: {}, current_user: anonymous).inspect("x").must_equal %{<Result:true [true] >} }
  it { Update.(params: {}, current_user: admin)    .inspect("x").must_equal %{<Result:true [nil] >} }

  #---
  #:callable-builder
  class MyBuilder
    def self.call(options, current_user:nil, **)
      current_user.admin? ? Create::Admin : Create::NeedsModeration
    end
  end
  #:callable-builder end

  #:callable
  class Delete < Trailblazer::Operation
    step Nested( MyBuilder )
    # ..
  end
  #:callable end

  it { Delete.(params: {}, current_user: anonymous).inspect("x").must_equal %{<Result:true [true] >} }
  it { Delete.(params: {}, current_user: admin)    .inspect("x").must_equal %{<Result:true [nil] >} }
end

class NestedWithCallableAndInputTest < Minitest::Spec
  Memo = Struct.new(:title, :text, :created_by)

  class Memo::Upsert < Trailblazer::Operation
    step Nested( :operation_class, input: :input_for_create )

    def operation_class( ctx, ** )
      ctx[:id] ? Update : Create
    end

    # only let :title pass through.
    def input_for_create( ctx )
      { title: ctx[:title] }
    end

    class Create < Trailblazer::Operation
      step :create_memo

      def create_memo( ctx, ** )
        ctx[:model] = Memo.new(ctx[:title], ctx[:text], :create)
      end
    end

    class Update < Trailblazer::Operation
      step :find_by_title

      def find_by_title( ctx, ** )
        ctx[:model] = Memo.new(ctx[:title], ctx[:text], :update)
      end
    end
  end

  it "runs Create without :id" do
    Memo::Upsert.( title: "Yay!" ).inspect(:model).
      must_equal %{<Result:true [#<struct NestedWithCallableAndInputTest::Memo title=\"Yay!\", text=nil, created_by=:create>] >}
  end

  it "runs Update without :id" do
    Memo::Upsert.( id: 1, title: "Yay!" ).inspect(:model).
      must_equal %{<Result:true [#<struct NestedWithCallableAndInputTest::Memo title=\"Yay!\", text=nil, created_by=:update>] >}
  end
end

# builder: Nested + deviate to left if nil / skip_track if true

#---
# automatic :name
class NestedNameTest < Minitest::Spec
  class Create < Trailblazer::Operation
    class Present < Trailblazer::Operation
      # ...
    end

    step Nested( Present )
    # ...
  end

  it { Operation::Inspect.(Create).must_equal %{[>>Nested(NestedNameTest::Create::Present)]} }
end
