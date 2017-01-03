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
    step     :assign_current_user!
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
    step     :authorize!
    failure  :auth_err!
    step     :save!
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
    step     :validate!

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

class DocsDependencyTest < Minitest::Spec
  Song = Struct.new(:id, :title, :created_by) do
    def save; true; end
  end
  Hit = Struct.new(:id)

  #:dep-op
  class Song::Create < Trailblazer::Operation
    self["my.model.class"] = Song

    #~dep-pipe
    step :model!

    def model!(options, **)
      options["my.model"] =           # setting runtime data.
        options["my.model.class"].new # reading class data at runtime.
    end
    #~dep-pipe end
  end
  #:dep-op end

  it do
    #:dep-op-class
    Song::Create["my.model.class"] #=> Song
    #:dep-op-class end

    #:dep-op-res
    result = Song::Create.({})

    result["my.model.class"] #=> Song
    result["my.model"] #=> #<Song title=nil>
    #:dep-op-res end

    Song::Create["my.model.class"].must_equal Song
    result["my.model.class"].must_equal Song
    result["my.model"].inspect.must_equal %{#<struct DocsDependencyTest::Song id=nil, title=nil, created_by=nil>}
  end

  it do
    #:dep-di
    result = Song::Create.({}, "my.model.class" => Hit)

    result["my.model"] #=> #<Hit id=nil>
    #:dep-di end
    result["my.model"].inspect.must_equal %{#<struct DocsDependencyTest::Hit id=nil>}
  end
end



class DocsOperationAPIExampleTest < Minitest::Spec
  Song = Struct.new(:id, :title, :created_by) do
    def save; true; end
  end

  class MyContract < Reform::Form
    property :title
    validates :title, presence: true
  end

  #:op-api
  class Song::Create < Trailblazer::Operation
    step    Model( Song, :new )
    step    :assign_current_user!
    step    Contract::Build( constant: MyContract )
    step    Contract::Validate()
    failure :log_error!
    step    Contract::Persist()

    def log_error!(options)
      # ..
    end

    def assign_current_user!(options)
      options["model"].created_by =
        options["current_user"]
    end
  end
  #:op-api end

  it { Song::Create.({ }).inspect("model").must_equal %{<Result:false [#<struct DocsOperationAPIExampleTest::Song id=nil, title=nil, created_by=nil>] >} }
  it { Song::Create.({ title: "Nothin'" }, "current_user"=>Module).inspect("model").must_equal %{<Result:true [#<struct DocsOperationAPIExampleTest::Song id=nil, title="Nothin'", created_by=Module>] >} }
end


class DocsOperationInheritanceTest < Minitest::Spec
  Song = Struct.new(:id, :title, :created_by) do
    def save; true; end
  end

  class MyContract < Reform::Form
    property :title
    validates :title, presence: true
  end

  #:inh-new
  class New < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build( constant: MyContract )
  end
  #:inh-new end

  puts New["pipetree"].inspect(style: :row)
=begin
  #:inh-new-pipe
   0 =======================>>operation.new
   1 ==========================&model.build
   2 =======================>contract.build
  #:inh-new-pipe end
=end

  #:inh-create
  class Create < New
    step Contract::Validate()
    step Contract::Persist()
  end
  #:inh-create end

  puts Create["pipetree"].inspect(style: :row)
=begin
  #:inh-create-pipe
   0 =======================>>operation.new
   1 ==========================&model.build
   2 =======================>contract.build
   3 ==============&contract.default.params
   4 ============&contract.default.validate
   5 =========================&persist.save
  #:inh-create-pipe end
=end

  module MyApp
  end

  #:override-app
  module MyApp::Operation
    class New < Trailblazer::Operation
      extend Contract::DSL

      contract do
        property :title
      end

      step Model( nil, :new )
      step Contract::Build()
    end
  end
  #:override-app end

  #:override-new
  class Song::New < MyApp::Operation::New
    step Model( Song, :new )
  end
  #:override-new end

  puts Song::New["pipetree"].inspect(style: :row)
=begin
  #:override-pipe
  Song::New["pipetree"].inspect(style: :row)
   0 =======================>>operation.new
   1 ==========================&model.build
   2 =======================>contract.build
  #:override-pipe end
=end

  it do
    Song::New.().inspect("model").must_equal %{<Result:true [#<struct DocsOperationInheritanceTest::Song id=nil, title=nil, created_by=nil>] >}
  end
end
