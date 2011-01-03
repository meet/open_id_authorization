class ExampleController < ApplicationController
  
  def authorize
    authorize_with_open_id('https://example.com/') do |result, identity, attributes|
      @result, @attributes = result, attributes
      render :nothing => true
    end
  end
  
  def authorize_from_config
    authorize_with_open_id() do |result, identity, attributes|
      @result, @attributes = result, attributes
      render :nothing => true
    end
  end
  
  def authorize_with_groups
    authorize_with_open_id(:required => [ :groups ]) do |result, identity, attributes|
      @result, @attributes = result, attributes
      render :nothing => true
    end
  end
  
end
