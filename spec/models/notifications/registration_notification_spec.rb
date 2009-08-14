require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe RegistrationNotification do
  
  it "includes user name, full name, password and activation link" do
    user = User.gen
    notification = RegistrationNotification.create(:user => user)
    body = notification.body
    body.should include("screen name")
    body.should include(user.name)
    body.should include("password:")
    body.should include(user.password)
    body.should include(user.activation_token)
  end

end
