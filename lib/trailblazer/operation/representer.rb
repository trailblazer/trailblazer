# Including this will change the way deserialization in #validate works.
#
# Instead of treating params as a hash and letting the form object deserialize it,
# a representer will be infered from the contract. This representer is then passed as
# deserializer into Form#validate.
#
# TODO: so far, we only support JSON, but it's two lines to change to support any kind of format.
#
# Needs self["model"].
# Needs #[], #[]= skill dependency.
module Trailblazer::Operation::Representer
  def self.included(includer)
    includer.extend DSL

    includer.extend Declarative::Heritage::Inherited
    includer.extend Declarative::Heritage::DSL
  end

  module DSL
    def representer(name=:default, constant=nil, &block)
      heritage.record(:representer, name, constant, &block)

      # FIXME: make this nicer. we want to extend same-named callback groups.
      # TODO: allow the same with contract, or better, test it!
      path, representer_class = Trailblazer::DSL::Build.new.({ prefix: :representer, class: representer_base_class, container: self }, name, constant, block)

      self[path] = representer_class
    end

    # TODO: make engine configurable?
    def representer_base_class
      Class.new(Representable::Decorator) { include Representable::JSON; self }
    end

    def infer_representer_class
      Disposable::Rescheme.from(self["contract.default.class"],
        include:          [Representable::JSON],
        options_from:     :deserializer, # use :instance etc. in deserializer.
        superclass:       Representable::Decorator,
        definitions_from: lambda { |inline| inline.definitions },
        exclude_options:  [:default, :populator], # TODO: test with populator: in an operation.
        exclude_properties: [:persisted?]
      )
    end
  end

  # Infer a representer from a contract.
  # This is not recommended and will probably extracted to a separate gem in TRB 2.0.
  module InferFromContract
    def self.included(includer)
      includer.extend Representer
    end

    module Representer
      def representer(name=:default, constant=nil, &block)
        unless name.is_a?(Class) || constant.is_a?(Class) # only invoke when NO constant is passed.
          return super(name, infer_representer_class, &block)
        end

        super
      end
    end

    def to_json(*)
      # TODO: optimize on class-level.
      self["representer.default.class"] ||= self.class.infer_representer_class
      super
    end

    def validate_contract(*)
      # TODO: optimize on class-level.
      self["representer.default.class"] ||= self.class.infer_representer_class
      super
    end
  end

private
  module Rendering
    # Override this if you need to pass options to the rendering.
    #
    #   def to_json(*)
    #     super(include: @params[:include])
    #   end
    def to_json(options={})
      self["representer.default.class"].new(represented).to_json(options)
    end

    # Override this if you want to render something else, e.g. the contract.
    def represented
      self["model"]
    end
  end
  include Rendering


  module Deserializer
    module Hash
      def validate_contract(params)
        # use the inferred representer from the contract for deserialization in #validate.
        contract.validate(params) do |document|
          self["representer.default.class"].new(contract).from_hash(document)
        end
      end
    end

    # This looks crazy, but all it does is using a Reform hook in #validate where we can use
    # our own representer for deserialization. After the object graph is set up, Reform will
    # run its validation without even knowing this came from JSON.
    module JSON
      def validate_contract(params)
        contract.validate(params) do |document|
          self["representer.default.class"].new(contract).from_json(document)
        end
      end
    end
  end
  include Deserializer::JSON
end
