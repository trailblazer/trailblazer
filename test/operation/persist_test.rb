require "test_helper"

class PersistTest < Minitest::Spec
  Song = Struct.new(:title, :saved) do
    def save; self.saved = true; end
  end

  class Create < Trailblazer::Operation
    extend Contract::DSL
    contract do
      property :title
    end

    self.| Model[Song, :create]
    self.| Contract[self["contract.default.class"]]
    self.| Contract::Validate[]
    self.< ->(input, options) { options["1. fail"] = "Validate" }, before: "operation.result"
    self.| Persist[]
  end

  it { Create.(title: "In Recital")["model"].title.must_equal "In Recital" }
  it { Create.(title: "In Recital")["model"].saved.must_equal true }
end
