# Including this will change the way deserialization in #validate works.
# Instead of treating params as a hash and letting the form object deserialize it,
# a representer will be infered from the contract. This representer is then passed as
# deserializer into Form#validate.
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
        include: [Representable::JSON],
        options_from: :deserializer, # use :instance etc. in deserializer.
        superclass:       Representable::Decorator,
        representer_from: lambda { |inline| inline.representer_class },
      )
    end

    def deserializer_class
      representer_class
    end
  end

  def validate_contract(params)
    # use the inferred representer from the contract for deserialization in #validate.
    contract.validate(params) do |json|
      self.class.deserializer_class.new(contract).from_json(json)
    end
  end
end