# controllers
class ApplicationController < ActionController::Base
end

class SongsController < ApplicationController
  respond_to :json, :js

  append_view_path "test/rails/fake_app/views"
  def index
    @users = Song.all.page params[:page]
    render inline: <<-ERB
<%= render_cell(:user, :show, @users) %>
ERB
  end

  include Trailblazer::Operation::Controller
  respond_to :html

  def create
    respond Song::Create
  end

  def create_with_params
    respond Song::Create, song: {title: "A Beautiful Indifference"}
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
  include Trailblazer::Operation::Controller
  respond_to :html

  def new
    present Band::Create

    render inline: <<-ERB
<%= form_for @form do |f| %>
  <%= f.text_field :name %>
<% end %>

<b><%= [@klass, @model.class, @form.is_a?(Reform::Form), @operation.class].join(",") %></b>
ERB
  end

  def new_with_block
    present Band::Create do |op|
      @klass = op.model.class
      @locality = params[:band][:locality]
    end

    render inline: <<-ERB
<b><%= [@klass, @model.class, @form.is_a?(Reform::Form), @operation.class, @locality].join(",") %></b>
ERB
  end

  def create
    respond Band::Create
  end

private
  def process_params!(params) # this is where you set :current_user, etc.
    params[:band] ||= {}
    params[:band][:locality] = "Essen"
  end
end