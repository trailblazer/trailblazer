require "uber/builder"

# Allows to add builders via ::builds.
class Trailblazer::Operation
  module Builder
    Step = ->(klass, options) { options["builder"].(options) }

    def self.[](proc)
      {
            step: Step,
            name: "builder.call",
          skills: { "builder" => proc },
        operator: :>>,
          before: "operation.new",
          inherit: false, # don't call `self.| Builder[]` on subclasses.
      }
    end

    def self.included(includer)
      includer.extend Uber::Builder::DSL # ::builds, ::builders
      includer.| self[ Uber::Builder::Constant.new(includer, includer, includer.builders) ]
    end
  end
end
