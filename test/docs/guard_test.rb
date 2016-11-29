require "test_helper"

class DocsGuardClassLevelTest < Minitest::Spec
  #---
  # class-level guard
  #:class-level
  class Create < Trailblazer::Operation
    self.| Policy::Guard[ ->(options) { options["current_user"] == Module } ],
      before: "operation.new"
    self.| ->(options) { options["x"] = true }
  end
  #:class-level end

  it { Create.(); Create["result.policy"].must_equal nil }
  it { Create.({}, "current_user" => Module)["x"].must_equal true }
  it { Create.({}                          )["x"].must_equal nil }
end

# TODO:
#policy.default
# no policy write on operation class.
