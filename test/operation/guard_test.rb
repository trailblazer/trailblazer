require "test_helper"

class GuardTest < Minitest::Spec
  #---
  # with proc, evaluated in operation context.
  class Create < Trailblazer::Operation
    self.| Policy::Guard[ ->(options) { options["params"][:pass] == self["params"][:pass] && options["params"][:pass] } ]
    self.| Call

    def process(*); self[:x] = true; end
    puts self["pipetree"].inspect(style: :rows)
  end

  it { Create.(pass: false)[:x].must_equal nil }
  it { Create.(pass: true)[:x].must_equal true }

  #- result object, guard
  it { Create.(pass: true)["result.policy"].success?.must_equal true }
  it { Create.(pass: false)["result.policy"].success?.must_equal false }

  # with Callable, operation passed in.
  class Update < Trailblazer::Operation
    class MyGuard
      include Uber::Callable
      def call(operation, options); options["params"][:pass] == operation["params"][:pass] && options["params"][:pass] end
    end

    self.| Policy::Guard[ MyGuard.new ]
    self.| Call

    def process(*); self[:x] = true; end
  end

  it { Update.(pass: false)[:x].must_equal nil }
  it { Update.(pass: true)[:x].must_equal true }

  #---
  #- Guard inheritance
  class New < Create
  end

  it { New["pipetree"].inspect.must_equal %{[>>operation.new,&policy.guard.evaluate,>Call]} }
end


# FIXME: what about block passed to ::policy?
