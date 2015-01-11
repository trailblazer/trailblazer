# BUNDLE_GEMFILE=gemfiles/Gemfile.rails bundle exec rake rails
require 'test_helper'

ActionController::TestCase.class_eval do
  setup do
    @routes = Rails.application.routes
  end
end

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
    assert_equal nil, song.length # params overwritten from controller.
  end
end

# overriding Controller#process_params.
class ProcessParamsTest < ActionController::TestCase
  tests BandsController

  setup do
    @routes = Rails.application.routes
  end

  test "Create with overridden #process_params" do
    post :create, band: {name: "Kreator"}
    assert_redirected_to band_path(Band.last)

    band = Band.last
    assert_equal "Kreator", band.name
    assert_equal "Essen", band.locality
  end
end

class ResponderRespondTest < ActionController::TestCase
  tests SongsController

  # HTML
  # #respond Create [valid]
  test "Create [html/valid]" do
    post :create, {song: {title: "You're Going Down"}}
    assert_redirected_to song_path(Song.last)
  end

  test "Create [html/invalid]" do
    post :create, {song: {title: ""}}
    assert_response 200
    assert_equal @response.body, "{:title=&gt;[&quot;can&#39;t be blank&quot;]}"
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


class ResponderRunTest < ActionController::TestCase
  tests BandsController

  test "[html/valid]" do
    put :update, {id: 1, band: {name: "Nofx"}}
    assert_equal "no block: Nofx, Essen, Band::Create", response.body
  end

  test "[html/valid] with builds" do
    put :update, {id: 1, band: {name: "Nofx"}, admin: true}
    assert_equal "no block: Nofx [ADMIN], Essen, Band::Create::Admin", response.body
  end

  test "with block [html/valid]" do
    put :update_with_block, {id: 1, band: {name: "Nofx"}}
    assert_equal "[valid] with block: Nofx, Essen", response.body
  end

  test "with block [html/invalid]" do
    put :update_with_block, {id: 1, band: {name: ""}}
  end
end

#present.
class ControllerPresentTest < ActionController::TestCase
  tests BandsController

  # let (:band) { }

  test "#present" do
    band = Band::Create[band: {name: "Nofx"}].model

    get :show, id: band.id

    assert_equal "bands/show.html: Band,Band,true,Band::Update,Essen\n", response.body
  end

  # TODO: this implicitely tests builds. maybe have separate test for that?
  test "#present [JSON]" do
    band = Band::Create[band: {name: "Nofx"}].model

    get :show, id: band.id, format: :json
    assert_equal "{\"name\":\"Nofx\"}", response.body
  end
end


# #form.
class ControllerFormTest < ActionController::TestCase
  tests BandsController

  test "#form" do
    get :new

    assert_select "form input#band_name"
    assert_select "b", ",Band,true,Band::Create"
  end

  test "#form with block" do
    get :new_with_block

    assert_select "b", "Band,Band,true,Band::Create,Essen"
  end

  test "#form with builder" do
    get :new, admin: true

    assert_select "b", ",Band,true,Band::Create::Admin"
  end
end