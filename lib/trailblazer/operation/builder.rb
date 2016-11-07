require "uber/builder"

# http://trailblazer.to/gems/operation/2.0/builder.html
class Trailblazer::Operation
  module Builder
    Step = ->(klass, options) { options["builder"].(options) }

    extend Stepable # :[]

    def self.import!(operation, pipe, user_builder)
      pipe.(:>>, Step,
        name:   "builder.call",
        before: "operation.new")

      operation["builder"] = user_builder
      false # suppress -inheritance. dislike. FIXME.
    end

    def self.included(includer)
      includer.extend Uber::Builder::DSL # ::builds, ::builders
      includer.| self[ Uber::Builder::Constant.new(includer, includer, includer.builders) ]
    end
  end
end
