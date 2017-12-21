require "test_helper"

class DocsModelTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find_by(id:nil)
      id.nil? ? nil : new(id)
    end

    def self.[](id)
      id.nil? ? nil : new(id+99)
    end
  end

  #:op
  class Create < Trailblazer::Operation
    step Model( Song, :new )
    # ..
  end
  #:op end

  it do
    #:create
    result = Create.(params: {})
    result[:model] #=> #<struct Song id=nil, title=nil>
    #:create end

    result[:model].inspect.must_equal %{#<struct DocsModelTest::Song id=nil, title=nil>}
  end

  #:update
  class Update < Trailblazer::Operation
    step Model( Song, :find_by )
    # ..
  end
  #:update end

  it do
    #:update-ok
    result = Update.(params: { id: 1 })
    result[:model] #=> #<struct Song id=1, title="Roxanne">
    #:update-ok end

    result[:model].inspect.must_equal %{#<struct DocsModelTest::Song id=1, title=nil>}
  end

  it do
    #:update-fail
    result = Update.(params: {})
    result[:model] #=> nil
    result.success? #=> false
    #:update-fail end

    result[:model].must_be_nil
    result.success?.must_equal false
  end

  #:show
  class Show < Trailblazer::Operation
    step Model( Song, :[] )
    # ..
  end
  #:show end

  it do
    result = Show.(params: { id: 1 })

    #:show-ok
    result = Show.(params: { id: 1 })
    result[:model] #=> #<struct Song id=1, title="Roxanne">
    #:show-ok end

    result.success?.must_equal true
    result[:model].inspect.must_equal %{#<struct DocsModelTest::Song id=100, title=nil>}
  end
end
