# Including this will change the way deserialization in #validate works.
#
# Instead of treating params as a hash and letting the form object deserialize it,
# a representer will be infered from the contract. This representer is then passed as
# deserializer into Form#validate.
#
# TODO: so far, we only support JSON, but it's two lines to change to support any kind of format.
module Trailblazer::Operation::Representer
  def self.included(base)
    base.extend DSL
  end

  module DSL
    def self.extended(extender)
      extender.inheritable_attr :_representer_class
    end

    def representer(constant=nil, &block)
      return representer_class unless constant or block_given?

      self.representer_class= Class.new(constant) if constant
      representer_class.class_eval(&block) if block_given?
    end

    def representer_class
      self._representer_class ||= infer_representer_class
    end

    def representer_class=(constant)
      self._representer_class = constant
    end

    require "disposable/version"
    def infer_representer_class
      if Disposable::VERSION =~ /^0.1/
        warn "[Trailblazer] Reform 2.0 won't be supported in Trailblazer 1.2. Don't be lazy and upgrade to Reform 2.1."

        Disposable::Twin::Schema.from(contract_class,
          include:          [Representable::JSON],
          options_from:     :deserializer, # use :instance etc. in deserializer.
          superclass:       Representable::Decorator,
          representer_from: lambda { |inline| inline.representer_class },
        )
      else
        Disposable::Rescheme.from(contract_class,
          include:          [Representable::JSON],
          options_from:     :deserializer, # use :instance etc. in deserializer.
          superclass:       Representable::Decorator,
          definitions_from: lambda { |inline| inline.definitions },
          exclude_options:  [:default, :populator], # TODO: test with populator: in an operation.
          exclude_properties: [:persisted?]
        )
      end
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
      self.class.representer_class.new(represented).to_json(options)
    end

    # Override this if you want to render something else, e.g. the contract.
    def represented
      model
    end
  end
  include Rendering


  module Deserializer
    module Hash
      def validate_contract(params)
        # use the inferred representer from the contract for deserialization in #validate.
        contract.validate(params) do |document|
          self.class.representer_class.new(contract).from_hash(document)
        end
      end
    end

    # This looks crazy, but all it does is using a Reform hook in #validate where we can use
    # our own representer for deserialization. After the object graph is set up, Reform will
    # run its validation without even knowing this came from JSON.
    module JSON
      def validate_contract(params)
        contract.validate(params) do |document|
          self.class.representer_class.new(contract).from_json(document)
        end
      end
    end
  end
  include Deserializer::JSON
end
