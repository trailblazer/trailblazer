require "uber/builder"

# http://trailblazer.to/gems/operation/2.0/builder.html
class Trailblazer::Operation
  module Builder
    extend Stepable # :[]

    def self.import!(operation, import, user_builder)
      import.(:>>, user_builder,
        name:   "builder.call",
        before: "operation.new")

      false # suppress inheritance. dislike. FIXME at some point.
    end

    # Include this when you want the ::builds DSL.
    def self.included(includer)
      includer.extend Uber::Builder::DSL # ::builds, ::builders
      includer.| self[ includer.builders ] # pass class Builders object to our ::import!.
    end
  end
end
