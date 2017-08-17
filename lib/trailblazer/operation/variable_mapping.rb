module Trailblazer
  class Activity
    # Ingoing options when calling a nested task.
    # @note This will be replaced with an ingoing options mapping in the TaskWrap in TRB 2.2.
    class Input
      def initialize(filter, strategy)
        @filter   = Trailblazer::Option(filter)
        @strategy = strategy
      end

      def call(direction, options, flow_options, task_conf, original_flow_options)
        # Trailblazer::Skill::KeywordHash @wrapped.(operation, options, runtime_data: options.to_runtime_data[0], mutable_data: options.to_mutable_data )
        # FIXME: almost identical with Option::KW.
        input_ctx = @filter.( options, original_flow_options )

        # TODO: is Context of hash?

        return direction, input_ctx, flow_options, task_conf.merge( original_context: options ), original_flow_options
      end
    end

    class Output < Input
      def call(direction, options, flow_options, task_conf, *args)
        original, options_for_filter = options.decompose

        output = @filter.(options_for_filter, **flow_options)       # this hash will get merged into options, per default.
        ctx    = @strategy.( task_conf[:original_context], output ) # here, we compute the "new" options {Context}.

        return direction, ctx, flow_options, task_conf, *args       # and then pass on the "new" context.
      end

      # "merge" Strategy
      class CopyMutableToOriginal
        # @param original Context
        # @param options  Context The object returned from a (nested) {Activity}.
        def self.call(original, mutable)
          mutable.each { |k,v| original[k] = v }

          original
        end
      end
    end
  end # Activity
end
