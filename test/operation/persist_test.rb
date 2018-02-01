require "test_helper"

class PersistTest < Minitest::Spec
  Song = Struct.new(:title, :saved) do
    def save; title=="Fail!" ? false : self.saved = true; end
  end

  class Create < Trailblazer::Operation
    class Form < Reform::Form
      property :title
    end

    class Fail1
      def self.call(options, **); options["1. fail"] = "Validate" end
    end

    class Fail2
      def self.call(options, **); options["2. fail"] = "Persist" end
    end

    step Model( Song, :new )
    step Contract::Build( constant: Form )
    step Contract::Validate()
    fail Fail1
    step Contract::Persist()
    fail Fail2
  end

  it { Create.(params: {title: "In Recital"})[:model].title.must_equal "In Recital" }
  it { Create.(params: {title: "In Recital"})[:model].saved.must_equal true }
  # failure
  it do
    result = Create.(params: {title: "Fail!"})
    result[:model].saved.must_be_nil
    result[:model].title.must_equal "Fail!"
    result["2. fail"].must_equal "Persist"
    result.success?.must_equal false
  end

  #---
  #- inheritance
  class Update < Create
  end

  it { Operation::Inspect.( Update ).must_equal %{[>model.build,>contract.build,>contract.default.validate,<<PersistTest::Create::Fail1,>persist.save,<<PersistTest::Create::Fail2]} }

  #---
  it do
    skip "show how save! could be applied and how we could rescue and deviate to left track"
  end
end
