require "test_helper"

class GuardTest < Minitest::Spec


  # with Callable, operation passed in.
  class Update < Trailblazer::Operation
    class MyGuard
      include Uber::Callable
      def call(options); options["params"][:pass] end
    end

    self.| Policy::Guard[ MyGuard.new ]
    self.| :process

    def process(*); self[:x] = true; end
  end

  it { Update.(pass: false)[:x].must_equal nil }
  it { Update.(pass: true)[:x].must_equal true }


end


# FIXME: what about block passed to ::policy?
