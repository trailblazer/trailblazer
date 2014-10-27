# BUNDLE_GEMFILE=gemfiles/Gemfile.rails bundle exec rake rails
require 'test_helper'

class ResponderTest < ActionController::TestCase
  tests SongsController

  setup do
    @routes = Rails.application.routes

    # 50.times {|i| User.create! :name => "user#{i}"}
  end

  # #respond Create [valid]
  test "#respond Create [valid]" do
    post :create, {song: {title: "You're Going Down"}}
    assert_redirected_to song_path(Song.last)
  end

  test "#respond Create [invalid]" do
    post :create, {song: {title: ""}}
    assert_equal @response.body, "{:title=&gt;[&quot;can&#39;t be blank&quot;]}"
  end

  # TODO: #present
  # TODO: #run
end