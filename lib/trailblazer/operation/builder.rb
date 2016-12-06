require "uber/builder"

# http://trailblazer.to/gems/operation/2.0/builder.html
class Trailblazer::Operation
  module Builder
    def self.import!(operation, import, user_builder)
      import.(:>>, user_builder,
        name:   "builder.call",
        before: "operation.new")

      false # suppress inheritance. dislike. FIXME at some point.
    end

    # Include this when you want the ::builds DSL.
    def self.included(includer)
      includer.extend DSL # ::builds, ::builders
      includer.| includer.Builder( includer.builders ) # pass class Builders object to our ::import!.
    end

    DSL = Uber::Builder::DSL
  end

  def self.Builder(*args, &block)
    [ Builder, args, block ]
  end
end
