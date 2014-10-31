# BUNDLE_GEMFILE=gemfiles/Gemfile.rails bundle exec rake rails
# TODO: how does rails handle all the different rake test tasks?

# require 'rails/all'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_record'

require 'fake_app/config'


# config
app = Class.new(Rails::Application)
app.config.secret_token = '3b7cd727ee24e8444053437c36cc66c4'
app.config.session_store :cookie_store, :key => '_myapp_session'
app.config.active_support.deprecation = :log
app.config.eager_load = false
# Rais.root
app.config.root = File.dirname(__FILE__)
Rails.backtrace_cleaner.remove_silencers!
app.initialize!

# routes
app.routes.draw do
  resources :songs do
    member do # argh.
      delete :destroy_with_formats
    end

    collection do
      post :create_with_params
    end
  end
end

require 'trailblazer/operation/responder'
require 'trailblazer/operation/controller'

require 'fake_app/controllers'
require 'fake_app/models'
require 'fake_app/song/operations.rb'

# helpers
Object.const_set(:ApplicationHelper, Module.new)
