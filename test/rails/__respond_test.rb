require "test_helper"
require "rack/test"

class Respond___Test < MiniTest::Spec
  include Rack::Test::Methods

  def app
    Rails.application
  end

  it "respond with :namespace" do
    # Rails.logger = Logger.new(STDOUT) # TODO: how do we get exceptions with rack-test?

    post "/songs/create_with_namespace", {title: "Teenager Liebe"}.to_json, "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT"=>"application/json"
    # puts last_response.inspect
    last_response.status.must_equal 201
    id = Song.last.id
    last_response.headers["Location"].must_equal "http://example.org/api/songs/#{id}"
  end
end