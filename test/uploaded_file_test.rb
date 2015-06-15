require 'test_helper'
require 'trailblazer/operation/uploaded_file'

class TempfileTest < MiniTest::Spec

end

class UploadedFileTest < MiniTest::Spec
  let (:image) { File.open("test/fixtures/apotomo.png") }
  let (:tempfile) { tmp = Tempfile.new("bla")
    tmp.write image.read
    tmp
   }

  let (:upload) { ActionDispatch::Http::UploadedFile.new(
    tempfile: tempfile,
    filename: "apotomo.png",
    type: "image/png")
  }

  describe "#to_hash" do
    before {
      @uploaded_path = upload.tempfile.path
      @subject = Trailblazer::Operation::UploadedFile.new(upload).to_hash
     }

    it { @subject[:filename].must_equal "apotomo.png" }
    it { @subject[:type].must_equal "image/png" }
    it { @subject[:tempfile_path].must_match /\w+_trailblazer_upload$/ }


    # Rails upload file must be removed.
    it {
      File.exists?(@uploaded_path).must_equal false }

    it { File.exists?(@subject[:tempfile_path]).must_equal true }
    it { File.size(@subject[:tempfile_path]).must_equal image.size }
  end

  describe "::from_hash" do
    let (:data) { Trailblazer::Operation::UploadedFile.new(upload).to_hash }
    subject { Trailblazer::Operation::UploadedFile.from_hash(data) }


    it { subject.original_filename.must_equal "apotomo.png" }
    it { subject.content_type.must_equal "image/png" }
    it { subject.tempfile.must_be_kind_of File }
    it { subject.size.must_equal image.size }

    # params is not modified.
    it { params = data.clone and subject; data.must_equal params }

    # Tempfile must have proper extension for further processing (sidekiq/imagemagick, etc).
    it { subject.tempfile.path.must_match /\.png$/ }

    # Tempfile must be unlinked after process is finished.
    it do
      @subject = Trailblazer::Operation::UploadedFile.from_hash(data)

      processable_file = @subject.tempfile.path
      File.exists?(processable_file).must_equal true # this file must be GCed since it's a Tempfile, that's the whole point.
      # @subject = nil
      # GC.start
      # File.exists?(processable_file).must_equal false
    end
  end


  describe "with custom tmp directory" do
    describe "#to_hash" do
      before {
        @uploaded = Trailblazer::Operation::UploadedFile.new(upload, tmp_dir: tmp_dir)
        @subject  = @uploaded.to_hash[:tempfile_path]
      }

      it { @subject.must_match /\w+_trailblazer_upload$/ }
      it { @subject.must_match /^\/tmp\/uploads\// }

      it { File.exists?(@subject).must_equal true }
      it { File.size(@subject).must_equal image.size }

      it { @uploaded.instance_variable_get(:@with_tmp_dir).path.must_equal nil }
    end
  end
end