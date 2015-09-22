require "test_helper"

class ResponderRespondTest < ActionController::TestCase
  tests SongsController

  # HTML
  # #respond Create [valid]
  test "Create [html/valid]" do
    post :create, {song: {title: "You're Going Down"}}
    assert_redirected_to song_path(Song.last)
  end

  test "Create [html/valid/location]" do
    post :other_create, {song: {title: "You're Going Down"}}
    assert_redirected_to other_create_songs_path
  end

  test "Create [html/invalid]" do
    post :create, {song: {title: ""}}
    assert_response 200
    assert_equal @response.body, "{:title=&gt;[&quot;can&#39;t be blank&quot;]}"
  end

  test "Create [html/invalid/action]" do
    post :other_create, {song: {title: ""}}
    assert_response 200
    assert_equal @response.body, "OTHER SONG\n{:title=&gt;[&quot;can&#39;t be blank&quot;]}\n"
    assert_template "songs/another_view"
  end

  test "Delete [html/valid]" do
    song = Song::Create[song: {title: "You're Going Down"}].model
    delete :destroy, id: song.id
    assert_redirected_to songs_path
    # assert that model is deleted.
  end

  test "respond with block [html/valid]" do
    post :create_with_block, {song: {title: "You're Going Down"}}
    assert_response 200
    assert_equal "block run, valid: true", response.body
  end

  test "respond with block [html/invalid]" do
    post :create_with_block, {song: {title: ""}}
    assert_response 200
    assert_equal "block run, valid: false", response.body
  end

  # JSON
  test "Delete [json/valid]" do
    song = Song::Create[song: {title: "You're Going Down"}].model
    delete :destroy, id: song.id, format: :json
    assert_response 204 # no content.
  end

  # JS
  test "Delete [js/valid]" do
    song = Song::Create[song: {title: "You're Going Down"}].model
    assert_raises ActionView::MissingTemplate do
      # js wants to render destroy.js.erb
      delete :destroy, id: song.id, format: :js
    end
  end

  test "Delete with formats [js/valid]" do
    song = Song::Create[song: {title: "You're Going Down"}].model

    delete :destroy_with_formats, id: song.id, format: :js
    assert_response 200
    assert_equal "Song slayer!", response.body
  end
end

class ResponderRespondWithJSONTest < ActionController::TestCase
  tests BandsController

  # JSON
  test "Create [JSON/valid]" do
    post :create, {name: "SNFU"}.to_json, format: :json
    assert_response 201
    assert_equal "SNFU", Band.last.name
  end
end

# TODO: merge with above tests on SongsController.
class ControllerRespondTest < ActionController::TestCase
  tests BandsController

  test "#respond with builds" do
    post :create, band: {name: "SNFU"}, admin: true
    assert_response 302
    assert_equal "SNFU [ADMIN]", Band.last.name
  end
end