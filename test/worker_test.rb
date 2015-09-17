# make sure #run always returns model

# in test with sidekiq/testing
# Operation.run #=> call perform_one and return [result, model] (model?)

require 'test_helper'
require 'trailblazer/operation'
require 'trailblazer/operation/worker'
require 'sidekiq/testing'


class WorkerTest < MiniTest::Spec
  class Operation < Trailblazer::Operation
    include Worker

    def process(params)
      with_symbol = params[:title]
      with_string = params["title"]
      @model = "I was working hard on #{params.inspect}. title:#{with_symbol} \"title\"=>#{with_string}"
    end
  end

  class NoBackgroundOperation < Operation
    def self.background?
      false
    end
  end

  # test basic worker functionality.
  describe "with sidekiq ss" do
    it do
      res = Operation.run(title: "Dragonfly")

      res.kind_of?(String).must_equal true # for now, we return the job from sidekiq
      Operation.jobs[0]["args"].must_equal([{"title"=>"Dragonfly"}])
      Operation.perform_one.last.model.must_equal "I was working hard on {\"title\"=>\"Dragonfly\"}. title:Dragonfly \"title\"=>Dragonfly"
    end
  end

  # without sidekiq, we don't have indifferent_access automatically.
  it { NoBackgroundOperation.run(title: "Dragonfly").last.model.must_equal "I was working hard on {:title=>\"Dragonfly\"}. title:Dragonfly \"title\"=>" }


  # test manual serialisation (to be done with UploadedFile etc automatically).
  class SerializingOperation < Operation
    include Worker

    def self.serializable(params)
      {wrap: params}
    end

    def deserializable(params)
      params[:wrap]
    end
  end

  describe "with serialization in sidekiq" do
    before { @res = SerializingOperation.run(title: "Dragonfly") }

    it { @res.kind_of?(String).must_equal true } # for now, we return the job from sidekiq.
    it { SerializingOperation.jobs[0]["args"].must_equal([{"wrap"=>{"title"=>"Dragonfly"}}]) }
    it { SerializingOperation.perform_one.last.model.must_equal "I was working hard on {\"title\"=>\"Dragonfly\"}. title:Dragonfly \"title\"=>Dragonfly" }
  end
end


require "trailblazer/operation/uploaded_file"
require "action_dispatch/http/upload"
class WorkerFileMarshallerTest < MiniTest::Spec
  def uploaded_file(name)
    tmp = Tempfile.new("bla")
    tmp.write File.open("test/fixtures/#{name}").read

    ActionDispatch::Http::UploadedFile.new(
    tempfile: tmp,
    filename: name,
    type: "image/png")
  end

  class Operation < Trailblazer::Operation
    contract do
      property :title
      property :image, file: true

      property :album do
        property :image, file: true
      end
    end

    include Worker
    include Worker::FileMarshaller # should be ContractFileMarshaller

    def process(params)
      @params = params
    end

    attr_reader :params
  end

  # TODO: no image

  # with image serializes the file for later retrieval.
  it do
    Operation.run(title: "Dragonfly", image: uploaded_file("apotomo.png"), album: {image: uploaded_file("cells.png")})

    args = Operation.jobs[0]["args"].first
    args["title"].must_equal("Dragonfly")
    args["image"]["filename"].must_equal "apotomo.png"
    args["image"]["tempfile_path"].must_match /trailblazer_upload/

    args["album"]["image"]["filename"].must_equal "cells.png"

    _, op = Operation.perform_one # deserialize.

    params = op.params

    params["title"].must_equal("Dragonfly")
    params[:title].must_equal("Dragonfly") # must allow indifferent_access.
    params["image"].must_be_kind_of ActionDispatch::Http::UploadedFile
    params["image"].original_filename.must_equal "apotomo.png"
    params["album"]["image"].must_be_kind_of ActionDispatch::Http::UploadedFile
    params["album"]["image"].original_filename.must_equal "cells.png"
  end
end