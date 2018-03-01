require "test_helper"

class DocsFailFastOptionTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find_by(id); nil end
  end

  class MyContract < Reform::Form
  end


  #:ffopt
  class Update < Trailblazer::Operation
    step    Model( Song, :find_by )
    failure :abort!,                                fail_fast: true
    step    Contract::Build( constant: MyContract )
    step    Contract::Validate( )
    failure :handle_invalid_contract!  # won't be executed if #abort! is executed.

    def abort!(options, params:, **)
      options["result.model.song"] = "Something went wrong with ID #{params[:id]}!"
    end
    # ..
  end
  #:ffopt end

  it { Update.(params: {id: 1}).inspect("result.model.song", "contract.default").must_equal %{<Result:false [\"Something went wrong with ID 1!\", nil] >} }
  it do
  #:ffopt-res
    result = Update.(params: {id: 1})
    result["result.model.song"] #=> "Something went wrong with ID 1!"
  #:ffopt-res end
  end
end

class DocsFailFastOptionWithStepTest < Minitest::Spec
  Song = Class.new do
    def self.find_by(*); Object end
  end

  #:ffopt-step
  class Update < Trailblazer::Operation
    step :empty_id?,             fail_fast: true
    step Model( Song, :find_by )
    failure :handle_empty_db!   # won't be executed if #empty_id? returns falsey.

    def empty_id?(options, params:, **)
      params[:id] # returns false if :id missing.
    end
  end
  #:ffopt-step end

  it { Update.(params: { id: nil }).inspect(:model).must_equal %{<Result:false [nil] >} }
  it { Update.(params: { id: 1 }).inspect(:model).must_equal %{<Result:true [Object] >} }
  it do
  #:ffopt-step-res
    result = Update.(params: { id: nil })

    result.failure? #=> true
    result["model"] #=> nil
  #:ffopt-step-res end
  end
end

class DocsPassFastWithStepOptionTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find_by(id); nil end
  end

  class MyContract < Reform::Form
  end

  #:pfopt-step
  class Update < Trailblazer::Operation
    step    Model( Song, :find_by )
    failure :abort!,                                fail_fast: true
    step    Contract::Build( constant: MyContract )
    step    Contract::Validate( )
    failure :handle_invalid_contract!  # won't be executed if #abort! is executed.

    def abort!(options, params:, **)
      options["result.model.song"] = "Something went wrong with ID #{params[:id]}!"
    end
    # ..
  end
  #:pfopt-step end

  it { Update.(params: {id: 1}).inspect("result.model.song", "contract.default").must_equal %{<Result:false [\"Something went wrong with ID 1!\", nil] >} }
  it do
  #:pfopt-step-res
    result = Update.(params: {id: 1})
    result["result.model.song"] #=> "Something went wrong with ID 1!"
  #:pfopt-step-res end
  end
end

class DocsFailFastMethodTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find_by(id); nil end
  end

  #:ffmeth
  class Update < Trailblazer::Operation
    step :filter_params!,         fast_track: true # emits fail_fast!
    step Model( Song, :find_by )
    failure :handle_fail!

    def filter_params!(options, params:, **)
      unless params[:id]
        options["result.params"] = "No ID in params!"
        return Railway.fail_fast!
      end
    end

    def handle_fail!(options, **)
      options["my.status"] = "Broken!"
    end
  end
  #:ffmeth end

  it { Update.(params: {}).inspect("result.params", "my.status").must_equal %{<Result:false [\"No ID in params!\", nil] >} }
  it do
  #:ffmeth-res
    result = Update.(params: {id: 1})
    result["result.params"] #=> "No ID in params!"
    result["my.status"]     #=> nil
  #:ffmeth-res end
  end
end

class DocsPassFastMethodTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def save; end
  end

  class MyContract < Reform::Form
  end

  #:pfmeth
  class Create < Trailblazer::Operation
    step Model( Song, :new )
    step :empty_model!,         fast_track: true  # emits pass_fast!
    step Contract::Build( constant: MyContract )
    # ..

    def empty_model!(options, is_empty:, model:, **)
      return unless is_empty
      model.save
      Railway.pass_fast!
    end
  end
  #:pfmeth end

  it { Create.(params: { title: "Tyrant"}, "is_empty" => true).inspect(:model).must_equal %{<Result:true [#<struct DocsPassFastMethodTest::Song id=nil, title=nil>] >} }
  it do
  #:pfmeth-res
    result = Create.(params: {}, "is_empty" => true)
    result["model"] #=> #<Song id=nil, title=nil>
  #:pfmeth-res end
  end
end


class FastTrackWithNestedTest < Minitest::Spec
  module Lib; end
  module Memo; end

  #:ft-nested
  class Lib::Authenticate < Trailblazer::Operation
    step :verify_input, fail_fast: true
    step :user_ok?
    #~ign
    def verify_input(options, w:true, **); options[:w] = true; w; end
    def user_ok?(options, u:true, **);     options[:u] = true; u; end
    #~ign end
  end
  #:ft-nested end

  #:ft-create
  class Memo::Create < Trailblazer::Operation
    step :validate
    step Nested( Lib::Authenticate ) # fail_fast goes to End.fail_fast
    step :create_model
    step :save
    #~igncr
    def validate(options, v:true, **);     options[:v] = true; v; end
    def create_model(options, c:true, **); options[:c] = true; c; end
    def save(options, s:true, **);         options[:s] = true; s; end
    #~igncr end
  end
  #:ft-create end

  it "everything goes :success ===> End.success" do
    result = Memo::Create.()

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:true [true, true, true, true, true] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Success
  end

  it "validate => failure ===> End.failure" do
    result = Memo::Create.(v: false)

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:false [true, nil, nil, nil, nil] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Failure
  end

  it "verify_input? => fail_fast ===> End.fail_fast" do
    result = Memo::Create.(w: false)

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:false [true, true, nil, nil, nil] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::FailFast
  end

  it "user_ok? => fail ===> End.failure" do
    result = Memo::Create.(u: false)

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:false [true, true, true, nil, nil] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Failure
  end

  it "create_model? => fail ===> End.failure" do
    result = Memo::Create.(c: false)

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:false [true, true, true, true, nil] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Failure
  end

  module Rewire
    module Memo; end

    #:ft-rewire
    class Memo::Create < Trailblazer::Operation
      step :validate
      step Nested( Lib::Authenticate ), Output(:fail_fast) => Track(:failure)
      step :create_model
      step :save
      #~ignrw
      def validate(options, v:true, **);     options[:v] = true; v; end
      def create_model(options, c:true, **); options[:c] = true; c; end
      def save(options, s:true, **);         options[:s] = true; s; end
      #~ignrw end
    end
    #:ft-rewire end
  end

  it "everything goes :success ===> End.success" do
    result = Rewire::Memo::Create.()

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:true [true, true, true, true, true] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Success
  end

  it "validate => failure ===> End.failure" do
    result = Rewire::Memo::Create.(v: false)

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:false [true, nil, nil, nil, nil] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Failure
  end

  # this is the only test differing.
  it "verify_input? => fail_fast ===> End.failure" do
    result = Rewire::Memo::Create.(w: false)

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:false [true, true, nil, nil, nil] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Failure
  end

  it "user_ok? => fail ===> End.failure" do
    result = Rewire::Memo::Create.(u: false)

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:false [true, true, true, nil, nil] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Failure
  end

  it "create_model? => fail ===> End.failure" do
    result = Rewire::Memo::Create.(c: false)

    result.inspect(:v,:w,:u,:c,:s).must_equal %{<Result:false [true, true, true, true, nil] >}
    result.event.must_be_instance_of Trailblazer::Operation::Railway::End::Failure
  end
end

# fail!
# pass!
