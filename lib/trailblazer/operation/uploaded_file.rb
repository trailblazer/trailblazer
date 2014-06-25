require 'trailblazer/operation'
require 'action_dispatch/http/upload'
require 'tempfile'

module Trailblazer
  class Operation::UploadedFile
    def initialize(uploaded)
      @uploaded = uploaded
    end

    def to_hash
      path = persist!

      {
        :filename       => @uploaded.original_filename,
        :type           => @uploaded.content_type,
        :tempfile_path  => path
      }
    end

    # Returns a ActionDispatch::Http::UploadedFile as if the upload was in the same request.
    def self.from_hash(hash)
      file   = File.open(hash[:tempfile_path])
      suffix = File.extname(hash[:tempfile_path])

      # we need to create a Tempfile to make Http::UploadedFile work.
      tmp = Tempfile.new(["bla", suffix]) # always force file suffix to avoid problems with imagemagick etc.
      tmp.write(file.read) # DISCUSS: can we avoid that? slow!
      # unlink file

      hash[:tempfile] = tmp

      ActionDispatch::Http::UploadedFile.new(hash)
    end

  private
     # convert Tempfile from Rails upload into persistent "temp" file so it is available in workers.
    def persist!
      File.rename(@uploaded.path, path = @uploaded.path + "_tmp")
      path
    end
  end
end