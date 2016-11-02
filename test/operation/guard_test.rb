require "test_helper"
require "trailblazer/operation/guard"

class GuardTest < Minitest::Spec
  #---
  # with proc, evaluated in operation context.
  class Create < Trailblazer::Operation
    include Policy::Guard
    policy ->(options) { options["params"][:pass] == self["params"][:pass] && options["params"][:pass] }
    def process(*); self[:x] = true; end
    puts self["pipetree"].inspect(style: :rows)
  end

  it { Create.(pass: false)[:x].must_equal nil }
  it { Create.(pass: true)[:x].must_equal true }
  # policy.result
  it { Create.(pass: true)["policy.result"].must_equal({"success?"=>true}) }
  it { Create.(pass: false)["policy.result"].must_equal({"success?"=>false}) }

  # with Callable, operation passed in.
  class Update < Create
    class MyGuard
      include Uber::Callable
      def call(operation, options); options["params"][:pass] == operation["params"][:pass] && options["params"][:pass] end
    end
    policy MyGuard.new
  end

  it { Update.(pass: false)[:x].must_equal nil }
  it { Update.(pass: true)[:x].must_equal true }
end


# FIXME: what about block passed to ::policy?
