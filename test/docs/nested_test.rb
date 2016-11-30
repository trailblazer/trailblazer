require "test_helper"

class DocsNestedOperationTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find(id)
      return new(1, "Bristol") if id == 1
    end
  end

  # self.> :bla!
  #   def bla!(options)
  #     self["model"] =
  #       self["result"]["model"]
  #     self["contract.default"] = self["result"]["contract.default"]
  #   end



  #---
  #- nested operations
  class Edit < Trailblazer::Operation
    extend Contract::DSL

    contract do
      property :title
    end

    self.| Model[ Song, :find ]
    self.| Contract::Build[]
  end

  class Update < Trailblazer::Operation
    self.| Nested[ Edit ] #, "policy.default" => self["policy.create"]
    self.| Contract::Validate[]
    self.| Persist[ method: :sync ]
  end

  puts Update["pipetree"].inspect(style: :rows)

  #-
  # Edit is successful.
  it do
    result = Update.({ id: 1, title: "Miami" }, "current_user" => Module)
    result.inspect("model").must_equal %{<Result:true [#<struct DocsNestedOperationTest::Song id=1, title="Miami">] >}
  end

  # Edit fails
  it do
    Update.(id: 2).inspect("model").must_equal %{<Result:false [nil] >}
  end

  #- shared data
  class B < Trailblazer::Operation
    self.> ->(options) { options["can.B.see.it?"] = options["this.should.not.be.visible.in.B"] }
    self.> ->(options) { options["can.B.see.current_user?"] = options["current_user"] }
    self.> ->(options) { options["can.B.see.A.class.data?"] = options["A.class.data"] }
  end

  class A < Trailblazer::Operation
    self["A.class.data"] = true

    self.> ->(options) { options["this.should.not.be.visible.in.B"] = true }
    self.| Nested[ B ]
  end

  # mutual data from A doesn't bleed into B.
  it { A.()["can.B.see.it?"].must_equal nil }
  it { A.()["this.should.not.be.visible.in.B"].must_equal true }
  # runtime dependencies are visible in B.
  it { A.({}, "current_user" => Module)["can.B.see.current_user?"].must_equal Module }
  # class data from A doesn't bleed into B.
  it { A.()["can.B.see.A.class.data?"].must_equal nil }


  # cr_result = Create.({}, "result" => result)
  # puts cr_result["model"]
  # puts cr_result["contract.default"]
end

class NestedClassLevelTest < Minitest::Spec
  #:class-level
  class New < Trailblazer::Operation
    self.| ->(options) { options["class"] = true }, before: "operation.new"
    self.| ->(options) { options["x"] = true }
  end

  class Create < Trailblazer::Operation
    self.| Nested[ New ]
    self.| ->(options) { options["y"] = true }
  end
  #:class-level end

  it { Create.().inspect("x", "y").must_equal %{<Result:true [true, true] >} }
  it { Create.(); Create["class"].must_equal nil }
end


# =begin
# class New
#   Model[Song, :create]
#   Policy :new
#   self.| :init!

#   def init!

#   end
# end

# class Create < Op
#   self.| New

#   Model[Song, :create]
#   Contract
#   Present
#   Persist
#   ->(*) { Mailer }

#   include Present
# end

# Create.(..., present: true)

# class Update < Create
# end

# =end
