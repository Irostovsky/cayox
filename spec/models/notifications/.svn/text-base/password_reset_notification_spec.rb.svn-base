require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe PasswordResetNotification do
  
  it "includes password_reset_token" do
    user = User.gen
    user.generate_password_reset_token
    notification = PasswordResetNotification.first(:order => [:id.desc])
    body = notification.body
    body.should include(user.password_reset_token)
  end

end
