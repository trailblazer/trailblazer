module Trailblazer
  class Activity
    # Ingoing options when calling a nested task.
    # @note This will be replaced with an ingoing options mapping in the TaskWrap in TRB 2.2.
    #
    # Assumption: we always have :input _and_ :output, where :input produces a Context and :output decomposes it.
    class Input
      def initialize(filter, strategy)
        @filter   = Trailblazer::Option(filter)
        @strategy = strategy
      end

      # `original_args` are the actual args passed to the wrapped task: [ [options, ..], circuit_options ]
      #
      def call((wrap_ctx, original_args), **)
        # Trailblazer::Skill::KeywordHash @wrapped.(operation, options, runtime_data: options.to_runtime_data[0], mutable_data: options.to_mutable_data )
        # FIXME: almost identical with Option::KW.

        (original_ctx, original_flow_options), original_circuit_options = original_args

        # let user compute new ctx for the wrapped task.
        input_ctx = @filter.( original_ctx, original_circuit_options )

        # wrap user's hash in Context if it's not one, already (in case user used options.merge).
        # DISCUSS: should we restrict user to .merge and options.Context?
        input_ctx = Trailblazer.Context({}, input_ctx) unless input_ctx.instance_of?(Trailblazer::Context)
        puts "-- input: #{input_ctx.object_id}"

        wrap_ctx = wrap_ctx.merge( vm_original_args: original_args )

        return Circuit::Right, [wrap_ctx, [[input_ctx, original_flow_options], original_circuit_options]]
      end
    end

    class Output < Input
      def call((wrap_ctx, original_args), **)


        (original_ctx, original_flow_options), original_circuit_options = original_args


        puts "&&&°°°° #{original_circuit_options.keys}"

        # (returned_ctx, returned_flow_options), returned_circuit_options = wrap_ctx[:result_args]
returned_ctx, _ = wrap_ctx[:result_args] # DISCUSS.

        # returned_ctx is the Context object from the nested operation. In <=2.1, this might be a completely different one
        # than "ours" we created in Input. We now need to compile a list of all added values. This is time-intensive and should
        # be optimized by removing as many Context creations as possible (e.g. the one adding self[] stuff in Operation.__call__).
        puts "-- output: #{returned_ctx.object_id}"

        _, mutable_data = returned_ctx.decompose

        # begin
        #   puts "@@@@@__x #{returned_ctx.class}"
        #   p mutable_data
        # end while returned_ctx != wrap_ctx[:vm_input_ctx]
        output = @filter.(mutable_data, **original_circuit_options)       # this hash will get merged into options, per default.

        (original_ctx, _), _ = wrap_ctx[:vm_original_args]

        ctx = @strategy.( original_ctx, output ) # here, we compute the "new" options {Context}.

        # wrap_ctx = wrap_ctx.merge( result_args: [ctx, returned_flow_options] ) # FIXME: this is wrong
        # raise wrap_ctx[:result_args][0].inspect
        wrap_ctx[:result_args][0] = ctx # FIXME: vomit

        return Circuit::Right, [wrap_ctx, *original_args]       # and then pass on the "new" context.
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
