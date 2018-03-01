require "test_helper"

# exec_context nach Nested

class NestedTest < Minitest::Spec
  #---
  #- shared data
  class B < Trailblazer::Operation
    pass ->(options, **) { options["can.B.see.A.mutable.data?"] = options["mutable.data.from.A"] }
    pass ->(options, **) { options["can.B.see.current_user?"]   = options["current_user"] }
    pass ->(options, **) { options["can.B.see.params?"]         = options["params"] }
    pass ->(options, **) { options["can.B.see.A.class.data?"]   = options["A.class.data"] }
    pass ->(options, **) { options["can.B.see.container.data?"] = options["some.container.data"] }
    pass ->(options, **) { options["mutable.data.from.B"]       = "from B!" }
  end

  class A < Trailblazer::Operation
    extend ClassDependencies
    self["A.class.data"] = "yes"                                   # class data on A

    pass ->(options, **) { options["mutable.data.from.A"] = "from A!" } # mutable data on A
    step Nested( B )
    pass ->(options, **) { options["can.A.see.B.mutable.data?"] = options["mutable.data.from.B"] }
  end

  #---
  #- default behavior: share everything.
  # no containers
  # no runtime data
  # no params
  it do
    result = A.("params" => {})
    # everything from A visible
    result["A.class.data"].       must_equal "yes"
    result["mutable.data.from.A"].must_equal "from A!"

    # B can see everything
    result["can.B.see.A.mutable.data?"].must_equal "from A!"
    result["can.B.see.current_user?"].must_be_nil
    result["can.B.see.params?"].must_equal({})
    result["can.B.see.A.class.data?"].must_equal "yes"
    result["can.B.see.container.data?"].must_be_nil

    result["can.A.see.B.mutable.data?"].must_equal "from B!"
  end

  #---
  #- Nested::NonActivity
  class AlmostB < Trailblazer::Operation
    step ->(options, is_successful:raise, **) { is_successful } # {AlmostB} fails if {is_successful} isn't true.
    step ->(options, **) { options["can.B.see.A.mutable.data?"] = options["mutable.data.from.A"] }
    pass ->(options, **) { options["mutable.data.from.B"]       = "from AlmostB!" }
  end

  #- Nested( ->{} )
  class SomeNestedWithProc < Trailblazer::Operation
    extend ClassDependencies
    self["A.class.data"] = "yes"                                   # class data on A

    Decider = ->(options, use_class:raise, **) { use_class }

    pass ->(options, **) { options["mutable.data.from.A"] = "from A!" } # mutable data on A
    step Nested( Decider )
    pass ->(options, **) { options["can.A.see.B.mutable.data?"] = options["mutable.data.from.B"] }
  end

  #- Nested( Callable )
  class SomeNestedWithCallable < Trailblazer::Operation
    extend ClassDependencies
    self["A.class.data"] = "yes"                                   # class data on A

    class Decider
      def self.call(options, use_class:raise, **)
        use_class
      end
    end

    pass ->(options, **) { options["mutable.data.from.A"] = "from A!" } # mutable data on A
    step Nested( Decider )
    pass ->(options, **) { options["can.A.see.B.mutable.data?"] = options["mutable.data.from.B"] }
  end

  #- Nested( :method )
  class SomeNestedWithMethod < Trailblazer::Operation
    extend ClassDependencies
    self["A.class.data"] = "yes"                                   # class data on A

    def decider(options, use_class:raise, **)
      use_class
    end

    pass ->(options, **) { options["mutable.data.from.A"] = "from A!" } # mutable data on A
    step Nested( :decider )
    pass ->(options, **) { options["can.A.see.B.mutable.data?"] = options["mutable.data.from.B"] }
  end


  #- test callable
  # B with Callable, successful
  it do
    result = SomeNestedWithCallable.("params" => {}, use_class: B)
    assert_b(result, is_successful: "whatever")
  end

  # AlmostB with Callable, successful
  it do
    result = SomeNestedWithCallable.("params" => {}, use_class: AlmostB, is_successful: true)
    assert_almost_b(result, is_successful: true)
  end

  # AlmostB with Callable, failure
  it do
    result = SomeNestedWithCallable.("params" => {}, use_class: AlmostB, is_successful: false)
    assert_almost_b(result, is_successful: false)
  end

  #- test proc
  # B with proc, successful
  it do
    result = SomeNestedWithProc.("params" => {}, use_class: B)
    assert_b(result, is_successful: "whatever")
  end

  # AlmostB with proc, successful
  it do
    result = SomeNestedWithProc.("params" => {}, use_class: AlmostB, is_successful: true)

    assert_almost_b(result, is_successful: true)
  end

  # AlmostB with proc, failure.
  it do
    result = SomeNestedWithProc.("params" => {}, use_class: AlmostB, is_successful: false)

    assert_almost_b(result, is_successful: false)
  end

  #- test :method
  # B with method, successful
  it do
    result = SomeNestedWithMethod.("params" => {}, use_class: B)
    assert_b(result, is_successful: "whatever")
  end

  # AlmostB with method, successful
  it do
    result = SomeNestedWithMethod.("params" => {}, use_class: AlmostB, is_successful: true)

    assert_almost_b(result, is_successful: true)
  end

  # AlmostB with method, failure.
  it do
    result = SomeNestedWithMethod.("params" => {}, use_class: AlmostB, is_successful: false)

    assert_almost_b(result, is_successful: false)
  end


  def assert_almost_b(result, is_successful:raise)
    result.success?.must_equal is_successful # AlmostB was successful, so A is successful.

    # everything from A visible
    result["A.class.data"].       must_equal "yes"
    result["mutable.data.from.A"].must_equal "from A!"

    # AlmostB doesn't look for everything
    result["can.B.see.current_user?"].must_be_nil
    result["can.B.see.params?"].must_be_nil
    if is_successful
      result["can.B.see.A.mutable.data?"].must_equal "from A!"
      result["can.B.see.A.class.data?"].must_be_nil # we don't look for it.
      result["can.A.see.B.mutable.data?"].must_equal "from AlmostB!"
    else
      result["can.B.see.A.mutable.data?"].must_be_nil
      result["can.B.see.A.class.data?"].must_be_nil
      result["can.A.see.B.mutable.data?"].must_be_nil
    end
    result["can.B.see.container.data?"].must_be_nil


    # result[:is_successful].must_equal is_successful # FIXME: this is wrong!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! key is symbol
  end

  def assert_b(result, is_successful:raise)
    # everything from A visible
    result["A.class.data"].       must_equal "yes"
    result["mutable.data.from.A"].must_equal "from A!"

    # B can see everything
    result["can.B.see.A.mutable.data?"].must_equal "from A!"
    result["can.B.see.current_user?"].must_be_nil
    result["can.B.see.params?"].must_equal({})
    result["can.B.see.A.class.data?"].must_equal "yes"
    result["can.B.see.container.data?"].must_be_nil

    result["can.A.see.B.mutable.data?"].must_equal "from B!"

    result[:is_successful].must_be_nil
    result.success?.must_equal true # B was successful, so A is successful.
  end


  #---
  #- :exec_context
  class Create < Trailblazer::Operation
    class Edit < Trailblazer::Operation
      step :c!

      def c!(options, **); options[:c] = 1 end
    end

    step :a!
    step Nested( Edit )
    step :b!

    def a!(options, **); options[:a] = 2 end
    def b!(options, **); options[:b] = 3 end
  end

  it { Create.().inspect(:a, :b, :c).must_equal %{<Result:true [2, 3, 1] >} }
end

class NestedWithFastTrackTest < Minitest::Spec
  module Steps
    def b(options, a:, **)
      options["b"] = a+1
    end

    def f(options, **)
      options["f"] = 3
    end
  end

  class Edit < Trailblazer::Operation
    pass :a, pass_fast: true

    def a(options, **)
      options["a"] = 1
    end
  end

  class Update < Trailblazer::Operation
    step Nested( Edit )
    step :b
    fail :f

    include Steps
  end

  # from Nested straight to End.pass_fast.
  it { Update.({}).inspect("a", "b", "f").must_equal %{<Result:true [1, nil, nil] >} }

  #- Nested, pass_fast: true
  class Upsert < Trailblazer::Operation
    step Nested( Edit ), pass_fast: true # this option is unnecessary.
    step :b
    fail :f

    include Steps
  end

  # from Nested straight to End.pass_fast.
  it { Upsert.({}).inspect("a", "b", "f").must_equal %{<Result:true [1, nil, nil] >} }

  #- mapping
  #- Nested, :pass_fast => :failure
  it "attaches :pass_fast => :failure" do
    op = Class.new(Trailblazer::Operation) do
      step Nested( Edit ), Output(:pass_fast) => Track(:failure)
      step :b
      fail :f

      include Steps
    end

    # from Nested to :failure track.
    op.({}).inspect("a", "b", "c", "f").must_equal %{<Result:false [1, nil, nil, 3] >}
  end

  it "goes straigt to End.failure" do
    op = Class.new(Trailblazer::Operation) do
      step Nested( Edit ), Output(:pass_fast) => "End.failure"
      step :b
      fail :f

      include Steps
    end

    # from Nested straight to End.failure, no fail step will be visited.
    op.({}).inspect("a", "b", "c", "f").must_equal %{<Result:false [1, nil, nil, nil] >}
  end
end
