# controllers
class ApplicationController < ActionController::Base
end

class SongsController < ApplicationController
  respond_to :json, :js

  append_view_path "test/rails/fake_app/views"
  def index
    @users = Song.all.page params[:page]
    render :inline => <<-ERB
<%= render_cell(:user, :show, @users) %>
ERB
  end

  include Trailblazer::Operation::Controller
  respond_to :html

  def create
    respond Song::Create
  end

  def destroy
    respond Song::Delete
  end

  def destroy_with_formats
    respond Song::Delete do |op, formats|
      formats.js { render text: "#{op.model.class} slayer!" }
    end
  end
end

class BandsController < ApplicationController

end