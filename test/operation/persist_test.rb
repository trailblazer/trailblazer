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

    step Model( Song, :new )
    step Contract::Build()
    step Contract::Validate()
    failure ->(options) { options["1. fail"] = "Validate" }
    step Contract::Persist()
    failure ->(options) { options["2. fail"] = "Persist" }
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

  it { Update["pipetree"].inspect.must_equal %{[>operation.new,>model.build,>contract.build,>contract.default.validate,<persist_test.rb:17,>persist.save,<persist_test.rb:19]} }

  #---
  it do
    skip "show how save! could be applied and how we could rescue and deviate to left track"
  end
end
