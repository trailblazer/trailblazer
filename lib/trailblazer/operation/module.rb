module Trailblazer::Operation::Module
  def self.included(base)
    base.extend ClassMethods
    base.extend Included
  end

  module Included # TODO: use representable's inheritance mechanism.
    def included(base)
      super
      instructions.each { |cfg|
        method  = cfg[0]
        args    = cfg[1].dup
        block   = cfg[2]
        # options = args.extract_options!.dup # we need to duplicate options has as AM::Validations messes it up later.

        base.send(method, *args, &block) } # property :name, {} do .. end
    end
  end

  module ClassMethods
    def method_missing(method, *args, &block)
      instructions << [method, args, block]
    end

    def instructions
      @instructions ||= []
    end
  end
end