require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe InvitationNotification do
  
  it "includes link with token and inviter full name" do
    user = User.invite("some@email.foo.com", User.gen)
    notification = Notification.first(:order => [:id.desc])
    body = notification.body
    body.should include(user.activation_token)
    body.should include(user.inviter.full_name)
  end
  
end
