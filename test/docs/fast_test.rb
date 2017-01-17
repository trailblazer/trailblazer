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

  it { Update.(id: 1).inspect("result.model.song", "contract.default").must_equal %{<Result:false [\"Something went wrong with ID 1!\", nil] >} }
  it do
  #:ffopt-res
    result = Update.(id: 1)
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

  it { Update.({ id: nil }).inspect("model").must_equal %{<Result:false [nil] >} }
  it { Update.({ id: 1 }).inspect("model").must_equal %{<Result:true [Object] >} }
  it do
  #:ffopt-step-res
    result = Update.({ id: nil })

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

  it { Update.(id: 1).inspect("result.model.song", "contract.default").must_equal %{<Result:false [\"Something went wrong with ID 1!\", nil] >} }
  it do
  #:pfopt-step-res
    result = Update.(id: 1)
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
    step :filter_params!         # emits fail_fast!
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

  it { Update.({}).inspect("result.params", "my.status").must_equal %{<Result:false [\"No ID in params!\", nil] >} }
  it do
  #:ffmeth-res
    result = Update.(id: 1)
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
    step :empty_model!                           # emits pass_fast!
    step Contract::Build( constant: MyContract )
    # ..

    def empty_model!(options, is_empty:, model:, **)
      return unless is_empty
      model.save
      Railway.pass_fast!
    end
  end
  #:pfmeth end

  it { Create.({ title: "Tyrant"}, "is_empty" => true).inspect("model").must_equal %{<Result:true [#<struct DocsPassFastMethodTest::Song id=nil, title=nil>] >} }
  it do
  #:pfmeth-res
    result = Create.({}, "is_empty" => true)
    result["model"] #=> #<Song id=nil, title=nil>
  #:pfmeth-res end
  end
end

# fail!
# pass!
