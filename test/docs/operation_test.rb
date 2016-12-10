require "test_helper"

class DocsOperationExampleTest < Minitest::Spec
  Song = Struct.new(:id, :title, :created_by) do
    def save; true; end
  end
  #:op

  class Song::Create < Trailblazer::Operation
    extend Contract::DSL

    contract do
      property :title
      validates :title, presence: true
    end

    step     Model( Song, :new )
    consider :assign_current_user!
    step     Contract::Build()
    step     Contract::Validate( )
    failure  :log_error!
    step     Contract::Persist(  )

    def log_error!(options)
      # ..
    end

    def assign_current_user!(options)
      options["model"].created_by =
        options["current_user"]
    end
  end
  #:op end

  it { Song::Create.({ }).inspect("model").must_equal %{<Result:false [#<struct DocsOperationExampleTest::Song id=nil, title=nil, created_by=nil>] >} }
  it { Song::Create.({ title: "Nothin'" }, "current_user"=>Module).inspect("model").must_equal %{<Result:true [#<struct DocsOperationExampleTest::Song id=nil, title="Nothin'", created_by=Module>] >} }
end
