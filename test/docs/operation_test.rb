require "test_helper"

class DocsOperationExampleTest < Minitest::Spec
  Song = Struct.new(:id, :title, :created_by) do
    def save; true; end
  end
  User = Struct.new(:name)

  #:invocation-dep
  class Create < Trailblazer::Operation
    step     Model( Song, :new )
    step     :assign_current_user!
    # ..
    def assign_current_user!(options)
      options["model"].created_by = options["current_user"]
    end
  end
  #:invocation-dep end

  it do
    current_user = User.new("Ema")
  #:invocation-dep-call
  result = Create.( { title: "Roxanne" }, "current_user" => current_user )
  #:invocation-dep-call end

  #:invocation-dep-res
  result["current_user"] #=> #<User name="Ema">
  result["model"]        #=> #<Song id=nil, title=nil, created_by=#<User name="Ema">>
  #:invocation-dep-res end
  end

  it { Create.({ title: "Roxanne" }, "current_user" => Module).inspect("model").must_equal %{<Result:true [#<struct DocsOperationExampleTest::Song id=nil, title=nil, created_by=Module>] >} }

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
    failure Wrap
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
    step Model( Song, :new ), override: true
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
    Song::New["pipetree"].inspect.must_equal %{[>operation.new,>model.build,>contract.build]}
    Song::New.().inspect("model").must_equal %{<Result:true [#<struct DocsOperationInheritanceTest::Song id=nil, title=nil, created_by=nil>] >}
  end
end

class DocsOperationStepOptionsTest < Minitest::Spec
  Song = Struct.new(:title) do
    def self.find_by(*)
      nil
    end
  end

  class AutomaticNameTest < Minitest::Spec
    #:name-auto
    class New < Trailblazer::Operation
      step Model( Song, :new )
    end
    #:name-auto end

    puts New["pipetree"].inspect(style: :row)
=begin
  #:name-auto-pipe
   0 =======================>>operation.new
   1 ==========================&model.build
  #:name-auto-pipe end
=end

    #:replace-inh
    class Update < New
      step Model(Song, :find_by), replace: "model.build"
    end
    #:replace-inh end

    puts Update["pipetree"].inspect(style: :row)
=begin
  #:replace-inh-pipe
   0 =======================>>operation.new
   2 ==========================&model.build
  #:replace-inh-pipe end
=end

    it { Update.({}).inspect("model").must_equal %{<Result:false [nil] >} }


#     #:delete-inh
#     class Noop < New
#       step nil, delete: "model.build"
#     end
#     #:delete-inh end

# puts "yo"
#     puts Update["pipetree"].inspect(style: :row)
# =begin
#   #:delete-inh-pipe
#    0 =======================>>operation.new
#    2 ==========================&model.build
#   #:delete-inh-pipe end
# =end

#     it { Noop.({}).inspect("model").must_equal %{<Result:false [nil] >} }
  end

  class ManualNameTest < Minitest::Spec
    #:name-manu
    class New < Trailblazer::Operation
      step Model( Song, :new ), name: "build.song.model"
      step :validate_params!,   name: "my.params.validate"
      # ..
    end
    #:name-manu end

    puts New["pipetree"].inspect(style: :row)
=begin
  #:name-manu-pipe
   0 =======================>>operation.new
   1 =====================&build.song.model
   2 ===================&my.params.validate
  #:name-manu-pipe end
=end
  end

  class BeforeTest < Minitest::Spec
    #:pos-before
    class New < Trailblazer::Operation
      step Model( Song, :new )
      step :validate_params!,   before: "model.build"
      # ..
    end
    #:pos-before end

    puts New["pipetree"].inspect(style: :row)
=begin
  #:pos-before-pipe
   0 =======================>>operation.new
   1 =====================&validate_params!
   2 ==========================&model.build
  #:pos-before-pipe end
=end

    #:pos-inh
    class Create < New
      step :policy!, after: "operation.new"
    end
    #:pos-inh end

    puts Create["pipetree"].inspect(style: :row)
=begin
  #:pos-inh-pipe
   0 =======================>>operation.new
   1 ==============================&policy!
   2 =====================&validate_params!
   3 ==========================&model.build
  #:pos-inh-pipe end
=end
  end
end
