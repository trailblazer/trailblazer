module Trailblazer::Operation::Representer
  def self.included(base)
    base.extend Uber::InheritableAttr
    base.inheritable_attr :representer_class
    # TODO: allow representer without contract?!
    base.extend ClassMethods
  end

  module ClassMethods
    def representer(&block)
      build_representer_class.class_eval(&block)
    end

    def build_representer_class
      self.representer_class ||= Class.new(

        Disposable::Twin::Schema.from(contract_class,
          include: [Representable::JSON],
          options_from: :deserializer, # use :instance etc. in deserializer.
          superclass:       Representable::Decorator,
          representer_from: lambda { |inline| inline.representer_class },
        )
      )
    end
  end
end