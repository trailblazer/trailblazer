require "test_helper"

module RailsEndpoint
  # this tests "the rails way" where both JSON and HTML operation use the pre-parsed params hash.
  class UnconfiguredTest < ActionDispatch::IntegrationTest
    class Create < Trailblazer::Operation
      include Model
      model Band

      def process(params)
        @model = Band.create(params["band"].permit(:name)) # how ridiculous is strong_parameters?
      end
    end

    class BandsController < ApplicationController
      include Trailblazer::Operation::Controller
      respond_to :html, :json
      # missing document_formats.

      def create
        run Create if request.format == :json
        run Create if request.format == :html
        render text: ""
      end
    end

    test "Create" do
      post "/rails_endpoint/unconfigured_test/bands", {band: {name: "SNFU"}}
      assert_response 200
      assert_equal "SNFU", Band.last.name
    end

    test "Create: JSON" do
      headers = { 'CONTENT_TYPE' => 'application/json' } # hahaha, oh god, rails, good bye!
      post "/rails_endpoint/unconfigured_test/bands", {band: {name: "Strike Anywhere"}}.to_json, headers
      assert_response 200
      assert_equal "Strike Anywhere", Band.last.name
    end
  end


  class ConfiguredTest < ActionDispatch::IntegrationTest
    class Create < Trailblazer::Operation
      include Model
      model Band

      def process(params)
        @model = Band.create(params["band"].permit(:name)) # how ridiculous is strong_parameters?
      end
    end

    class JSONCreate < Trailblazer::Operation
      include Model
      model Band

      def process(params)
        @model = Band.create(JSON.parse(params["band"])) # document comes in keyed as "band".
      end

    end

    class BandsController < ApplicationController
      include Trailblazer::Operation::Controller
      respond_to :html, :json

      def create
        run Create if request.format == :html
        run JSONCreate if request.format == :json
        render text: ""
      end
    end

    test "Create" do
      post "/rails_endpoint/configured_test/bands", {band: {name: "All"}}
      assert_response 200
      assert_equal "All", Band.last.name
    end

    test "Create: JSON" do
      post "/rails_endpoint/configured_test/bands.json", {name: "NOFX"}.to_json#, headers # FIXME: headers do not work
      assert_response 200
      assert_equal "NOFX", Band.last.name
    end
  end
end