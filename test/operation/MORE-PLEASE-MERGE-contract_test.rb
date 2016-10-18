require "test_helper"

class OperationContractMERGEMETest < Minitest::Spec
  class Operation < Trailblazer::Operation
    include Contract
    attr_reader :model

    contract do
      property :id
      property :title
      property :length
    end

    def process(params)
      @model = Struct.new(:id, :title, :length).new

      contract.id = 1
      validate(params) do
        contract.length = 3
      end
    end
  end

  # allow using #contract before #validate.
  it do
    contract = Operation.(title: "Beethoven")[:contract]
    contract.id.must_equal 1
    contract.title.must_equal "Beethoven"
    contract.length.must_equal 3
  end
end

class OperationContractWithTwinOptionsTest < Minitest::Spec
  class Operation < Trailblazer::Operation
    include Contract
    contract do
      property :id
      property :title, virtual: true
    end

    def process(params)
      model = Struct.new(:id).new

      contract(model, title: "Bad Feeling")

      validate(params)
    end
  end

  # allow using #contract to inject model and arguments.
  it do
    op = Operation.(id: 1)[:operation]
    op.contract.id.must_equal 1
    op.contract.title.must_equal "Bad Feeling"
  end

  describe "#contract with Composition" do
    class CompositionOperation < Trailblazer::Operation
      include Contract
      contract do
        include Reform::Form::Composition
        property :song_id,    on: :song
        property :album_name, on: :album
        property :title,      virtual: true
      end

      def process(params)
        song  = Struct.new(:song_id).new(1)
        album = Struct.new(:album_name).new("Forever Malcom Young")

        contract({ song: song, album: album }, title: "Medicine Balls")

        validate(params)
      end
    end

    it do
      contract = CompositionOperation.({})[:contract]
      contract.song_id.must_equal 1
      contract.album_name.must_equal "Forever Malcom Young"
      contract.title.must_equal "Medicine Balls"
    end
  end

  describe "#validate with Composition" do
    class CompositionValidateOperation < Trailblazer::Operation
      include Contract
      contract do
        include Reform::Form::Composition
        property :song_id,    on: :song
        property :album_name, on: :album
        property :title,      virtual: true
      end

      def process(params)
        song  = Struct.new(:song_id).new(1)
        album = Struct.new(:album_name).new("Forever Malcom Young")

        validate(params, { song: song, album: album }, title: "Medicine Balls")
      end
    end

    it do
      contract = CompositionValidateOperation.({})[:contract]
      contract.song_id.must_equal 1
      contract.album_name.must_equal "Forever Malcom Young"
      contract.title.must_equal "Medicine Balls"
    end
  end
end

class OperationContractWithTwinOptionsAndContractClassTest < Minitest::Spec
  class Operation < Trailblazer::Operation
    class Contract < Reform::Form
      property :title, virtual: true
    end

    def process(params)
      contract(Object.new, { title: "Bad Feeling" }, Contract)

      validate(params)
    end
  end

  # allow using #contract to inject model, options and class.
  it do
    contract = Operation.(id: 1)[:contract]
    contract.title.must_equal "Bad Feeling"
    contract.must_be_instance_of Operation::Contract
  end
end
