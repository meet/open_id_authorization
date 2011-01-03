require 'test_helper'

class ExampleFlowTest < ActionController::IntegrationTest
  
  test "should respect X-Forwarded-Proto" do
    OpenID.fetcher = OpenIdAuthorization::MockOpenIdFetcher.new('https://openid.server/')
    
    OpenID.fetcher.respond_with_provider_xrds
    OpenID.fetcher.respond_with_unsupported
    get '/example/authorize', {}, { 'HTTP_X_FORWARDED_PROTO' => 'https' }
    params = Rack::Utils.parse_query(response.redirect_url)
    assert_equal 'https://www.example.com', params['openid.realm']
    assert_equal 'https://www.example.com/example/authorize', params['openid.return_to']
    
    OpenID.fetcher.respond_with_user_xrds('tom')
    OpenID.fetcher.respond_with_valid
    get '/example/authorize',
        OpenID.fetcher.response_from_checkid('tom', 'maine', 'https://www.example.com/example/authorize'),
        { 'HTTP_X_FORWARDED_PROTO' => 'https' }
    assert assigns(:result).successful?
    assert_equal 'tom', assigns(:attributes)[:username]
  end
  
  test "mock fetcher session module should fake login" do
    OpenIdAuthorization.provider = 'https://openid.server/'
    open_session do |s|
      s.extend(OpenIdAuthorization::MockOpenIdFetcher::Session)
      
      s.login('/example/authorize_with_groups', 'jerry', 'maine,hawaii')
      
      s.assert_response :success
      assert s.assigns(:result).successful?
      assert_equal 'jerry', s.assigns(:attributes)[:username]
      assert_equal [ 'maine', 'hawaii' ], s.assigns(:attributes)[:groups]
    end
  end
  
end
