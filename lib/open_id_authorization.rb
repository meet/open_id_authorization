require 'rails'
require 'open_id_authentication'

class OpenIdAuthorizationRailtie < Rails::Railtie
  
  config.app_middleware.use OpenIdAuthentication
  
  config.after_initialize do
    # First open_id_authentication...
    OpenID::Util.logger = Rails.logger
    ActionController::Base.send :include, OpenIdAuthentication
    # ... and now us
    ActionController::Base.send :include, OpenIdAuthorization::Controller
  end
end

# Monkey patch Rack::OpenID to respect X-Forwarded-Proto
module Rack
  class OpenID
    
    def self.with_forwarded_proto(method)
      orig = self.instance_method(method)
      define_method(method) do |env, *args|
        ports = { 'http' => '80', 'https' => '443' }
        server_port = env['SERVER_PORT']
        url_scheme = env['rack.url_scheme']
        begin
          if forwarded = env['HTTP_X_FORWARDED_PROTO']
            env['SERVER_PORT'] = ports[forwarded] if server_port == ports[url_scheme]
            env['rack.url_scheme'] = forwarded
          end
          return orig.bind(self).call(env, *args)
        ensure
          env['SERVER_PORT'] = server_port
          env['rack.url_scheme'] = url_scheme
        end
      end
    end
    
    with_forwarded_proto(:begin_authentication)
    with_forwarded_proto(:complete_authentication)
    
  end
end

module OpenIdAuthorization
  
  OPEN_ID_AX_SCHEMA = {
    :username => 'http://axschema.org/namePerson/friendly',
    :groups => 'http://id.meet.mit.edu/schema/groups-csv'
  }
  
  def self.provider
    @@provider
  end
  
  def self.provider=(provider)
    @@provider = provider
  end
  
end

require 'open_id_authorization/controller'
require 'open_id_authorization/mock_open_id_fetcher'
