# Including this will change the way deserialization in #validate works.
#
# Instead of treating params as a hash and letting the form object deserialize it,
# a representer will be infered from the contract. This representer is then passed as
# deserializer into Form#validate.
#
# TODO: so far, we only support JSON, but it's two lines to change to support any kind of format.
module Trailblazer::Operation::Representer
  def self.included(base)
    base.extend Uber::InheritableAttr
    base.inheritable_attr :_representer_class
    base.extend ClassMethods
  end

  module ClassMethods
    def representer(&block)
      representer_class.class_eval(&block)
    end

    def representer_class
      self._representer_class ||= infer_representer_class
    end

    def representer_class=(constant)
      self._representer_class = constant
    end

    def infer_representer_class
      Disposable::Twin::Schema.from(contract_class,
        include:          [Representable::JSON],
        options_from:     :deserializer, # use :instance etc. in deserializer.
        superclass:       Representable::Decorator,
        representer_from: lambda { |inline| inline.representer_class },
      )
    end
  end

private
  module Rendering
    def to_json(*)
      self.class.representer_class.new(represented).to_json
    end

    def represented
      contract
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
        # use the inferred representer from the contract for deserialization in #validate.
        contract.validate(params) do |document|
          self.class.representer_class.new(contract).from_json(document)
        end
      end
    end
  end
  include Deserializer::JSON
end