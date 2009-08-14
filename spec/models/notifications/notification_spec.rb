require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe Notification do
  
  it "should remove entries older than N days" do
    user = User.gen
    user.generate_password_reset_token
    notification = user.notifications.first(:order => [:id.desc])
    lambda do
      Notification.remove_old!(5)
    end.should_not change(Notification, :count)
    notification.update_attributes(:created_at => 6.days.ago)
    lambda do
      Notification.remove_old!(5)
    end.should change(Notification, :count).by(-1)
  end

  it "should remove all invalid entries" do
    user = User.gen
    topic = Topic.gen
    topic.add_owner(User.gen)
    topic.add_owner(user)
    notification = RoleAssignedNotification.first(:order => [:id.desc])
    lambda do
      Notification.remove_invalid!
    end.should_not change(Notification, :count)
    topic.remove!
    lambda do
      Notification.remove_invalid!
    end.should change(Notification, :count).by(-1)
  end

  it "should ignore invalid entry when resending" do
    user = User.gen
    topic = Topic.gen
    topic.add_owner(User.gen)
    topic.add_owner(user)
    notification = RoleAssignedNotification.first(:order => [:id.desc])
    topic.remove!
    lambda do
      notification.send!
    end.should_not change(Merb::Mailer.deliveries, :count)
    lambda do
      SummaryNotification.send!(notification.user, [notification])
    end.should_not change(Merb::Mailer.deliveries, :count)
  end
  
end
