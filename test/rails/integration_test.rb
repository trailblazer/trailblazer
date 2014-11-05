require 'test_helper'

class IntegrationTest < ActionController::TestCase
  tests BandsController

  # test rendering JSON of populated band.
  test "#present [JSON]" do
    band = Band::Create[band: {name: "Nofx", songs: [{title: "Murder The Government"}, {title: "Eat The Meek"}]}].model

    get :show, id: band.id, format: :json
    assert_equal "{\"name\":\"Nofx\",\"songs\":[{\"title\":\"Murder The Government\"},{\"title\":\"Eat The Meek\"}]}", response.body
  end

  # parsing incoming complex document.
  test "create [JSON]" do
    post :create, "{\"name\":\"Nofx\",\"songs\":[{\"title\":\"Murder The Government\"},{\"title\":\"Eat The Meek\"}]}", format: :json
    assert_response 201

    band = Band.last
    assert_equal "Nofx", band.name
    assert_equal "Murder The Government", band.songs[0].title
  end
end