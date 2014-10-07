require 'sidekiq/worker'
# require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'


class Trailblazer::Operation
  # only kicks in when Operation::run, #run will still do it real-time
  module Worker
    def self.included(base)
      base.send(:include, Sidekiq::Worker) # TODO: this will work with any bg gem.
      base.extend(ClassMethods)
    end

    module ClassMethods
      def run(params)
        if background?
          return perform_async(serializable(params))
        end

        new.run(params)
      end

    private
      def background? # TODO: make configurable.
        true
        # if Rails.env == "production" or Rails.env == "staging"
      end

      def serializable(params)
        params # this is where we convert file uloads into Trailblazer::UploadedFile, etc. soon.
      end
    end


    # called from Sidekiq.
    def perform(params)
      # the serialized params hash from Sidekiq contains a Op::UploadedFile hash.

      # the following code is basically what happens in a controller.
      # this is a bug in Rails, it doesn't work without requiring as/hash/ina
      # params = ActiveSupport::HashWithIndifferentAccess.new_from_hash_copying_default(params) # TODO: this might make it ultra-slow as Reform converts it back to strings. fuck that.
      params = params.with_indifferent_access

      run(deserializable(params))
    end

  private
    def deserializable(params)
      params # this is where we convert file uloads into Trailblazer::UploadedFile, etc. soon.
    end


    # Overrides ::serializable and #deserializable and handles file properties from the Contract schema.
    module FileMarshaller
      # nested_forms do |attr|
      #   attr.merge!(

      module ToHash
        def to_hash
          representable_attrs.each do |dfn| # TODO: copy so we don't pollute. also, this can be done once.
            dfn.merge! :getter => lambda { |*| self[dfn.name.to_sym] } # FIXME: allow both sym and str.

            next unless dfn[:file]
            # TODO: where do we set /tmp/uploads?
            dfn.merge!(:representable => true, :serialize => lambda { |file, *| Trailblazer::Operation::UploadedFile.new(file, :tmp_dir => "/tmp/uploads").to_hash })
          end

          # TODO: nested, copied!

          super
        end

      end

    private
      def serializable(params)
        # TODO: API to retrieve representable_attrs
        new({}).send(:contract_class).representer_class.new(params).extend(ToHash).to_hash
      end
    end
  end
end
