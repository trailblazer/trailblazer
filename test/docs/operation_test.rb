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

class DndTest < Minitest::Spec
  class Create < Trailblazer::Operation
    consider :authorize!
    failure  :auth_err!
    consider :save!
    self.< Wrap
  end
end

class DocsResultTest < Minitest::Spec
  Song = Struct.new(:id, :title, :created_by) do
    def save; true; end
  end

  #:step-options
  class Song::Create < Trailblazer::Operation
    step     :model!
    step     :assign!
    consider :validate!

    def model!(options, current_user:, **)
      options["model"] = Song.new
      options["model"].created_by = current_user
    end

    def assign!(*, params:, model:, **)
      model.title= params[:title]
    end

    #:step-val
    def validate!(options, model:, **)
      options["result.validate"] = ( model.created_by && model.title )
    end
    #:step-val end
  end
  #:step-options end

  it do
    current_user = Struct.new(:email).new("nick@trailblazer.to")
  #:step-res
  result = Song::Create.({ title: "Roxanne" }, "current_user" => current_user)

  result["model"] #=> #<Song title="Roxanne", "created_by"=<User ...>
  result["result.validate"] #=> true
  #:step-res end

    result.inspect("current_user", "model").must_equal %{<Result:true [#<struct email=\"nick@trailblazer.to\">, #<struct DocsResultTest::Song id=nil, title="Roxanne", created_by=#<struct email=\"nick@trailblazer.to\">>] >}

  #:step-binary
  result.success? #=> true
  result.failure? #=> falsee
  #:step-binary end

  #:step-dep
  result["current_user"] #=> <User ...>
  #:step-dep end

  #:step-inspect
  result.inspect("current_user", "model") #=> "<Result:true [#<User email=\"nick@tra... "
  #:step-inspect end
  end
end
