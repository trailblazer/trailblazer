require "test_helper"


class OperationContractTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
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
    op = Operation.(title: "Beethoven")
    op.contract.id.must_equal 1
    op.contract.title.must_equal "Beethoven"
    op.contract.length.must_equal 3
  end
end

class OperationContractWithTwinOptionsTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
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
    op = Operation.(id: 1)
    op.contract.id.must_equal 1
    op.contract.title.must_equal "Bad Feeling"
  end

  describe "#contract with Composition" do
    class CompositionOperation < Trailblazer::Operation
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
      op = CompositionOperation.({})
      op.contract.song_id.must_equal 1
      op.contract.album_name.must_equal "Forever Malcom Young"
      op.contract.title.must_equal "Medicine Balls"
    end
  end

  describe "#validate with Composition" do
    class CompositionValidateOperation < Trailblazer::Operation
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
      op = CompositionValidateOperation.({})
      op.contract.song_id.must_equal 1
      op.contract.album_name.must_equal "Forever Malcom Young"
      op.contract.title.must_equal "Medicine Balls"
    end
  end
end

class OperationContractWithTwinOptionsAndContractClassTest < MiniTest::Spec
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
    op = Operation.(id: 1)
    op.contract.title.must_equal "Bad Feeling"
    op.contract.must_be_instance_of Operation::Contract
  end
end

class OperationContractWithDeprecatedArgumentsTest < MiniTest::Spec # TODO: remove in 1.3.
  class Operation < Trailblazer::Operation
    contract do
      property :id
      property :title, virtual: true
    end

    Contract = Class.new(contract_class)

    def process(params)
      model = Struct.new(:id).new

      contract(model, Contract) # use contract class where should be options now!

      validate(params)
    end
  end

  # allow using #contract to inject model and arguments.
  it do
    op = Operation.(id: 1)
    op.contract.id.must_equal 1
    op.contract.class.must_equal Operation::Contract
  end
end
