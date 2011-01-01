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

# Very simple mock OpenID URL fetcher.
class MockOpenIDFetcher
  
  def initialize
    @responses = []
  end
  
  def respond(url, body='', status=200, headers={})
    response = OpenID::HTTPResponse._from_net_response(Net::HTTPResponse.new(1.1, status.to_s, 'NONE'), url)
    response.initialize_http_header headers
    response.body = body
    @responses.push response
  end
  
  def respond_with_provider_xrds(url)
    respond(url, <<-DOC)
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      <Type>http://specs.openid.net/auth/2.0/server</Type>
      <URI>https://example.com/openid</URI>
    </Service>
  </XRD>
</xrds:XRDS>
    DOC
  end
  
  def respond_with_unsupported(url)
    respond(url, <<-DOC)
ns:http://specs.openid.net/auth/2.0
error:mocking
error_code:unsupported-type
    DOC
  end
  
  def fetch(url, body=nil, headers=nil, limit=nil)
    @responses.shift
  end
  
end
