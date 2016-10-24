class Trailblazer::Operation
  New  = ->(klass, options) { klass.new(options[:params], options[:skills]) } # returns operation instance.
  Call = ->(operation, options) { operation.call(options[:params]) }          # returns #call result.

  module Pipetree
    def self.included(includer)
      includer.extend ClassMethods
      includer.extend Pipe

      includer.| New
      includer.| Call
    end

    module ClassMethods
      def call(params={}, options={})
        pipe = self["pipetree"] # TODO: injectable? WTF? how cool is that?


        result = {}
        skills = Trailblazer::Skill.new(result, options, self.skills) # FIXME: redundant from Op::Skill.

        outcome = pipe.(self, { skills: skills, params: params }) # (class, { skills: , params: })

        outcome == ::Pipetree::Stop ? result : outcome # THIS SUCKS a bit.

        # FIXME: simply return op?
      end
    end

    module Pipe
      def |(func, options=nil)
        self["pipetree"] ||= ::Pipetree[]
        options ||= { append: true } # per default, append.

        self["pipetree"].insert!(func, options)#.class.inspect
      end
    end
  end
end
