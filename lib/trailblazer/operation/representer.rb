class Trailblazer::Operation
  module Representer
    def self.infer(contract_class, format:Representable::JSON)
      Disposable::Rescheme.from(contract_class,
        include:          [format],
        options_from:     :deserializer, # use :instance etc. in deserializer.
        superclass:       Representable::Decorator,
        definitions_from: lambda { |inline| inline.definitions },
        exclude_options:  [:default, :populator], # TODO: test with populator: in an operation.
        exclude_properties: [:persisted?]
      )
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
    end
  end
end
