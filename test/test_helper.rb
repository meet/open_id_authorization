require 'rubygems'
require 'bundler/setup'

require 'open_id_authorization'

ENV['RAILS_ENV'] = 'test'
require 'example_app/config/environment'
require 'rails/test_help'

require 'test/app/example_controller.rb'

ExampleApp::Application.routes.draw do
  match ':controller(/:action(/:id))'
end
