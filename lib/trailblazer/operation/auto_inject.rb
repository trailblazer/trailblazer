require "dry/auto_inject"

class Trailblazer::Operation
  # Thanks, @timriley! <3
  # https://gist.github.com/timriley/d314a58da9784912159006e208ba8ea9
  module AutoInject
    class InjectStrategy < Module
      ClassMethods = Class.new(Module)

      attr_reader :container
      attr_reader :dependency_map
      attr_reader :class_mod

      def initialize(container, *dependency_names)
        @container = container
        @dependency_map = Dry::AutoInject::DependencyMap.new(*dependency_names)
        @class_mod = ClassMethods.new
      end

      def included(klass)
        define_call

        klass.singleton_class.prepend @class_mod

        super
      end

      private

      def define_call
        class_mod.class_exec(container, dependency_map) do |container, dependency_map|
          define_method :call do |params={}, options={}, *dependencies|
            options_with_deps = dependency_map.to_h.each_with_object({}) { |(name, identifier), obj|
              obj[name] = options[name] || container[identifier]
            }.merge(options)

            super(params, options_with_deps, *dependencies)
          end
        end
      end
    end
  end

  def self.AutoInject(container)
    Dry::AutoInject(container, strategies: {default: AutoInject::InjectStrategy})
  end
end
