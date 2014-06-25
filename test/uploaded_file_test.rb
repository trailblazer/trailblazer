require 'test_helper'
require 'trailblazer/operation/uploaded_file'

class UploadedFileTest < MiniTest::Spec
  let (:image) { File.open("test/fixtures/apotomo.png") }
  let (:tempfile) { tmp = Tempfile.new("bla")
    tmp.write image.read
    tmp
   }

  let (:upload) { ActionDispatch::Http::UploadedFile.new(
    :tempfile => tempfile,
    :filename => "apotomo.png",
    :type     => "image/png")
  }

  describe "#to_hash" do
    subject { Trailblazer::Operation::UploadedFile.new(upload).to_hash }

    it { subject[:filename].must_equal "apotomo.png" }
    it { subject[:type].must_equal "image/png" }
    it { subject[:tempfile_path].must_match /\w+_tmp/ }

    it { File.exists?(subject[:tempfile_path]) }
  end

  describe "::from_hash" do
    let (:data) { Trailblazer::Operation::UploadedFile.new(upload).to_hash }
    subject { Trailblazer::Operation::UploadedFile.from_hash(data) }


    it { subject.original_filename.must_equal "apotomo.png" }
    it { subject.content_type.must_equal "image/png" }
    it { subject.tempfile.must_be_kind_of File }
  end

end