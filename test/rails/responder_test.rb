require 'test_helper'

class ResponderTest < ActionController::TestCase
  tests SongsController

  setup do
    @routes = Rails.application.routes

    # 50.times {|i| User.create! :name => "user#{i}"}
  end

  # #respond Create [valid]
  test "rendering normal cell" do
    post :create, {song: {title: "You're Going Down"}}

    assert_redirected_to song_path(Song.last)
  end

  # TODO: #present
  # TODO: #run
end