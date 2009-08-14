require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Sign-in form" do

  it "should successfully sign-in activated, non-blocked user" do
    user = User.gen(:password => "qwe123", :password_confirmation => "qwe123")
    response = request("/login", :method => 'put', :params => { :login => user.name, :password => user.password }, :xhr => true)
    response.should redirect
  end

  it "should show message for invalid credentials" do
    response = request("/login", :method => 'put', :params => { :login => "foo", :password => "bar" }, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest')
    response.status.should == 401
    response.should have_selector("div.error li:contains('password')")
  end

  it "should show message for inactive user" do
    user = User.gen(:inactive, :password => "qwe123", :password_confirmation => "qwe123")
    response = request("/login", :method => 'put', :params => { :login => user.name, :password => user.password }, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest')
    response.status.should == 401
    response.should have_selector("div.error li:contains('activate')")
  end

  it "should show message for blocked user" do
    user = User.gen(:blocked => true, :password => "qwe123", :password_confirmation => "qwe123")
    response = request("/login", :method => 'put', :params => { :login => user.name, :password => user.password }, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest')
    response.status.should == 401
    response.should have_selector("div.error li:contains('blocked')")
  end
  
end
