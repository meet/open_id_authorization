require 'test_helper'

class ExampleControllerTest < ActionController::TestCase
  
  test "should request username" do
    get :authorize
    assert_response :unauthorized
    auth_header = response.headers[Rack::OpenID::AUTHENTICATE_HEADER]
    assert_match 'required="http://axschema.org/namePerson/friendly"', auth_header
  end
  
  test "should use server from config" do
    OpenIdAuthorization.provider = 'https://openid.server/'
    get :authorize_from_config
    assert_response :unauthorized
    auth_header = response.headers[Rack::OpenID::AUTHENTICATE_HEADER]
    assert_match 'identifier="https://openid.server/"', auth_header
  end
  
  test "requiring groups should request username and groups" do
    OpenIdAuthorization.provider = 'https://openid.server/'
    get :authorize_with_groups
    assert_response :unauthorized
    auth_header = response.headers[Rack::OpenID::AUTHENTICATE_HEADER]
    assert_match /required=".*http:\/\/axschema.org\/namePerson\/friendly.*"/, auth_header
    assert_match /required=".*http:\/\/id.meet.mit.edu\/schema\/groups-csv.*"/, auth_header
  end
  
end
