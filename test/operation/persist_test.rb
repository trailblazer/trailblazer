require "test_helper"

class PersistTest < Minitest::Spec
  Song = Struct.new(:title, :saved) do
    def save; title=="Fail!" ? false : self.saved = true; end
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
    self.< ->(input, options) { options["2. fail"] = "Persist" }, before: "operation.result"
  end

  it { Create.(title: "In Recital")["model"].title.must_equal "In Recital" }
  it { Create.(title: "In Recital")["model"].saved.must_equal true }
  # failure
  it do
    result = Create.(title: "Fail!")
    result["model"].saved.must_equal nil
    result["model"].title.must_equal "Fail!"
    result["2. fail"].must_equal "Persist"
    result.success?.must_equal false
  end

  #---
  #- inheritance
  class Update < Create
  end

  it { Update["pipetree"].inspect.must_equal %{[>>operation.new,&model.build,>contract.build,&contract.validate,<self,&persist.save,<self,operation.result]} }

  #---
  it do
    skip "show how save! could be applied and how we could rescue and deviate to left track"
  end
end
