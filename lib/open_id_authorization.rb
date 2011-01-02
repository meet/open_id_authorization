require 'rails'
require 'open_id_authentication'

class OpenIdAuthorizationRailtie < Rails::Railtie
  
  config.app_middleware.use OpenIdAuthentication
  
  config.after_initialize do
    # First open_id_authentication...
    OpenID::Util.logger = Rails.logger
    ActionController::Base.send :include, OpenIdAuthentication
    # ... and now us
    ActionController::Base.send :include, OpenIdAuthorization
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
  
  protected
  
  def authorize_with_open_id(provider = nil, options = {})
    provider, options = nil, provider if provider.is_a? Hash
    provider ||= OpenIdAuthorization.provider
    
    options[:required] ||= []
    options[:required].map! { |r| r.is_a?(Symbol) ? OPEN_ID_AX_SCHEMA[r] : r }
    username = OPEN_ID_AX_SCHEMA[:username]
    options[:required].push(username) unless options[:required].include?(username)
    
    authenticate_with_open_id(provider, options) do |result, identity_url|
      if result.successful?
        ax = OpenID::AX::FetchResponse.from_success_response(request.env[Rack::OpenID::RESPONSE])
        attributes = {}
        options[:required].each do |r|
          value = ax.get(r)
          attributes[r] = value.length == 1 ? value.first : value
        end
        OPEN_ID_AX_SCHEMA.each do |sym, url|
          if attributes.key?(url)
            attributes[sym] = url.ends_with?('-csv') ? attributes[url].split(',') : attributes[url]
          end
        end
      end
      
      yield result, identity_url, attributes
    end
  end
  
end
