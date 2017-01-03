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
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end
  #:update end

  puts Update["pipetree"].inspect(style: :rows)

  #-
  # Edit allows grabbing model and contract
  it do
  #:edit-call
  result = Edit.(id: 1)

  result["model"]            #=> #<Song id=1, title=\"Bristol\">
  result["contract.default"] #=> #<Reform::Form ..>
  #:edit-call end
    result.inspect("model").must_equal %{<Result:true [#<struct DocsNestedOperationTest::Song id=1, title=\"Bristol\">] >}
    result["contract.default"].model.must_equal result["model"]
  end

  #-
  # Update also allows grabbing model and contract
  it do
  #:update-call
  result = Update.(id: 1, title: "Call It A Night")

  result["model"]            #=> #<Song id=1 , title=\"Call It A Night\">
  result["contract.default"] #=> #<Reform::Form ..>
  #:update-call end
    result.inspect("model").must_equal %{<Result:true [#<struct DocsNestedOperationTest::Song id=1, title=\"Call It A Night\">] >}
    result["contract.default"].model.must_equal result["model"]
  end

  #-
  # Edit is successful.
  it do
    result = Update.({ id: 1, title: "Miami" }, "current_user" => Module)
    result.inspect("model").must_equal %{<Result:true [#<struct DocsNestedOperationTest::Song id=1, title="Miami">] >}
  end

  # Edit fails
  it do
    Update.(id: 2).inspect("model").must_equal %{<Result:false [nil] >}
  end

  #- shared data
  class B < Trailblazer::Operation
    self.> ->(options) { options["can.B.see.it?"] = options["this.should.not.be.visible.in.B"] }
    self.> ->(options) { options["can.B.see.current_user?"] = options["current_user"] }
    self.> ->(options) { options["can.B.see.A.class.data?"] = options["A.class.data"] }
  end

  class A < Trailblazer::Operation
    self["A.class.data"] = true

    self.> ->(options) { options["this.should.not.be.visible.in.B"] = true }
    step Nested B
  end

  # mutual data from A doesn't bleed into B.
  it { A.()["can.B.see.it?"].must_equal nil }
  it { A.()["this.should.not.be.visible.in.B"].must_equal true }
  # runtime dependencies are visible in B.
  it { A.({}, "current_user" => Module)["can.B.see.current_user?"].must_equal Module }
  # class data from A doesn't bleed into B.
  it { A.()["can.B.see.A.class.data?"].must_equal nil }


  # cr_result = Create.({}, "result" => result)
  # puts cr_result["model"]
  # puts cr_result["contract.default"]
end

class NestedClassLevelTest < Minitest::Spec
  #:class-level
  class New < Trailblazer::Operation
    step ->(options) { options["class"] = true }, before: "operation.new"
    step ->(options) { options["x"] = true }
  end

  class Create < Trailblazer::Operation
    step Nested New
    step ->(options) { options["y"] = true }
  end
  #:class-level end

  it { Create.().inspect("x", "y").must_equal %{<Result:true [true, true] >} }
  it { Create.(); Create["class"].must_equal nil }
end

class NestedWithCallableTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  class X < Trailblazer::Operation
    step ->(options) { options["x"] = true }
  end

  class Y < Trailblazer::Operation
    step ->(options) { options["y"] = true }
  end

  class A < Trailblazer::Operation
    step ->(options) { options["z"] = true }
    step Nested( ->(options, *) { options["class"] } )
  end

  it { A.({}, "class" => X).inspect("x", "y", "z").must_equal "<Result:true [true, nil, true] >" }
  it { A.({}, "class" => Y).inspect("x", "y", "z").must_equal "<Result:true [nil, true, true] >" }
  # it { Create.({}).inspect("x", "y", "z").must_equal "<Result:true [nil, true, true] >" }

  class Song
    module Contract
      class Create < Reform::Form
        property :title
      end
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

  it { Create.({}, "current_user" => anonymous).inspect("x").must_equal %{<Result:true [true] >} }
  it { Create.({}, "current_user" => admin)    .inspect("x").must_equal %{<Result:true [nil] >} }

  class Update < Trailblazer::Operation
    step Nested( :build! )

    def build!(options, current_user:nil, **)
      current_user.admin? ? Create::Admin : Create::NeedsModeration
    end
  end

  it { Update.({}, "current_user" => anonymous).inspect("x").must_equal %{<Result:true [true] >} }
  it { Update.({}, "current_user" => admin)    .inspect("x").must_equal %{<Result:true [nil] >} }

  class MyBuilder
    extend Uber::Callable
    def self.call(options, current_user:nil, **)
      current_user.admin? ? Create::Admin : Create::NeedsModeration
    end
  end

  class Delete < Trailblazer::Operation
    step Nested( MyBuilder )

    def build!(options, current_user:nil, **)
      current_user.admin? ? Create::Admin : Create::NeedsModeration
    end
  end

  it { Delete.({}, "current_user" => anonymous).inspect("x").must_equal %{<Result:true [true] >} }
  it { Delete.({}, "current_user" => admin)    .inspect("x").must_equal %{<Result:true [nil] >} }
end

# builder: Nested + deviate to left if nil / skip_track if true
