require 'test_helper'

class ExampleFlowTest < ActionController::IntegrationTest
  
  test "should respect X-Forwarded-Proto" do
    OpenID.fetcher = MockOpenIDFetcher.new
    OpenID.fetcher.respond_with_provider_xrds 'https://example.com/'
    OpenID.fetcher.respond_with_unsupported 'https://example.com/openid'
    get '/example/authorize', {}, { 'X-FORWARDED-PROTO' => 'https' }
    params = Rack::Utils.parse_query(response.redirect_url)
    assert_equal 'https://www.example.com', params['openid.realm']
    assert_equal 'https://www.example.com/example/authorize', params['openid.return_to']
  end
  
end
