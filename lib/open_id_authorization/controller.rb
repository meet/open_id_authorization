module OpenIdAuthorization
  module Controller
    
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
end
