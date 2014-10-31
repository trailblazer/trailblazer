# BUNDLE_GEMFILE=gemfiles/Gemfile.rails bundle exec rake rails
require 'test_helper'

class GenericResponderTest < ActionController::TestCase
  tests SongsController

  setup do
    @routes = Rails.application.routes
  end

  test "Create with params" do
    post :create_with_params, {song: {title: "You're Going Down", length: 120}}
    assert_response 302

    song = Song.last
    assert_equal "A Beautiful Indifference", song.title
    assert_equal nil, song.length
  end
end

class ResponderRespondTest < ActionController::TestCase
  tests SongsController

  setup do
    @routes = Rails.application.routes
  end

  # HTML
  # #respond Create [valid]
  test "Create [html/valid]" do
    post :create, {song: {title: "You're Going Down"}}
    assert_redirected_to song_path(Song.last)
  end

  test "Create [html/invalid]" do
    post :create, {song: {title: ""}}
    assert_equal @response.body, "{:title=&gt;[&quot;can&#39;t be blank&quot;]}"
  end

  test "Delete [html/valid]" do
    song = Song::Create[song: {title: "You're Going Down"}].model
    delete :destroy, id: song.id
    assert_redirected_to songs_path
    # assert that model is deleted.
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

  # TODO: #present
  # TODO: #run

  # describe "#run" do
  #   test "#run" do

  # end
  # end



end


class ResponderRunTest < ActionController::TestCase
  tests BandsController

  test "Create [html/valid]" do

  end
end