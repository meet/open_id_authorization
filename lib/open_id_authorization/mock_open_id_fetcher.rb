module OpenIdAuthorization
  
  # Very simple mock OpenID URL fetcher.
  class MockOpenIdFetcher
    
    # Module to include in an ActionController::IntegrationTest session.
    module Session
      def login(url, username, groups)
        OpenID.fetcher = MockOpenIdFetcher.new('https://openid.example.com/')
        
        OpenID.fetcher.respond_with_provider_xrds
        OpenID.fetcher.respond_with_unsupported
        get(url)
        assert_match /openid.mode=checkid_setup/, response.redirect_url
        
        OpenID.fetcher.respond_with_user_xrds(username)
        OpenID.fetcher.respond_with_valid
        get(url, OpenID.fetcher.response_from_checkid(username, groups, request.url))
      end
    end
    
    # Create a new mock OpenID URL fetcher.
    def initialize(base)
      @responses = []
      @base = base
      @endpoint = "#{base}endpoint"
    end
    
    # Enqueue a response.
    def respond(url, body='', status=200, headers={})
      response = OpenID::HTTPResponse._from_net_response(Net::HTTPResponse.new(1.1, status.to_s, 'NONE'), url)
      response.initialize_http_header headers
      response.body = body
      @responses.push response
    end
    
    # Enqueue a response to the base URL with the provider discovery information.
    def respond_with_provider_xrds
      respond(@base, <<-DOC)
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      <Type>#{OpenID::OPENID_IDP_2_0_TYPE}</Type>
      <URI>#{@endpoint}</URI>
    </Service>
  </XRD>
</xrds:XRDS>
      DOC
    end
    
    # Enqueue a response to a user URL with the user discovery information.
    def respond_with_user_xrds(username)
      respond("#{@base}#{username}", <<-DOC)
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      <Type>#{OpenID::OPENID_2_0_TYPE}</Type>
      <URI>#{@endpoint}</URI>
    </Service>
  </XRD>
</xrds:XRDS>
      DOC
    end
    
    # Construct the GET parameters that would be present when the user is redirected after authentication.
    def response_from_checkid(username, groups, return_to)
      response = {
        'ns' => OpenID::OPENID2_NS,
        'mode' => 'id_res',
        'op_endpoint' => @endpoint,
        'claimed_id' => "#{@base}#{username}",
        'identity' => "#{@base}#{username}",
        'return_to' => return_to,
        'response_nonce' => OpenID::Nonce.mk_nonce,
        'assoc_handle' => '1',
        'sig' => '1',
        'ns.ax' => OpenID::AX::AXMessage::NS_URI,
        'ax.mode' => 'fetch_response',
        'ax.type.username' => 'http://axschema.org/namePerson/friendly',
        'ax.type.groups' => 'http://id.meet.mit.edu/schema/groups-csv',
        'ax.value.username' => username,
        'ax.value.groups' => groups
      }
      openid = {}
      response.each { |key, value| openid["openid.#{key}"] = value }
      openid['openid.signed'] = response.keys.join(',')
      return openid
    end
    
    # Enqueue a response to the provider URL with an unsupported association type error.
    def respond_with_unsupported
      respond(@endpoint, "ns:#{OpenID::OPENID2_NS}\nerror:Mocking\nerror_code:unsupported-type")
    end
    
    # Enqueue a response to the provider URL with a signature is valid message.
    def respond_with_valid
      respond(@endpoint, "ns:#{OpenID::OPENID2_NS}\nis_valid:true")
    end
    
    # Return the next enqueued response. Called by OpenID.
    def fetch(url, body=nil, headers=nil, limit=nil)
      return @responses.shift
    end
    
  end
end
