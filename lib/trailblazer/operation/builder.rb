require "uber/builder"

# Allows to add builders via ::builds.
class Trailblazer::Operation
  Build = ->(klass, options) { klass.class_builder(klass).(options) }

  module Builder
    # TODO: move to compat.
    def self.extended(extender)
      raise "[Trailblazer] Please `include Builder` instead of `extend`."
    end

    def self.included(includer)
      # FIXME: that is unnecessary.
      includer.send(:extend, BuilderClass) # ::builder_class.
      includer.send(:include, Uber::Builder) # ::builds.

      includer.>> Build, before: "operation.new", name: "operation.build"
    end

    # FIXME: use self[] and fix that in Uber::Builder (still relies on Class@builders).
    module BuilderClass
      def builder_class
        @builders
      end

      def builder_class=(constant)
        @builders = constant
      end
    end
  end
end
