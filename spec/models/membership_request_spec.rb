require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe MembershipRequest do

  before(:each) do
    @topic = Topic.gen
    @topic.add_owner(User.gen)
    @topic_owner = User.gen(:primary_language => Language["pl"])
    @topic.add_owner(@topic_owner)
    @topic_maintainer = User.gen
    @topic.add_maintainer(@topic_maintainer)
  end

  it "should not create two same MembershipRequests" do
    first = MembershipRequest.create(:user_id => 1, :topic_id => 1)
    second = MembershipRequest.new(:user_id => 1, :topic_id => 1).should_not be_valid
  end
  
  it "should deliver daily notifications to all owners with data from all projects" do
    # 3 new users in one single topic
    users = [User.gen, User.gen, User.gen]
    users.each do |user|
      MembershipRequest.create(:user_id => user.id, :topic_id => @topic.id)
    end
    
    lambda do
      MembershipRequest.daily_notification
    end.should change(Merb::Mailer.deliveries, :length).by(2)
    
    users.map do |x|
      Merb::Mailer.deliveries.last.text.should include(x.name)
    end

  end
  
  it "should send compiled emails with all topics changes to moderators" do
    topic = Topic.gen
    topic.add_owner(User.gen)
    other_topic = Topic.gen
    other_topic.add_owner(User.gen)
    topic_owner = User.gen(:primary_language => Language["pl"])
    topic_owner.sig_members.create(:topic => topic, :role => :owner)
    topic_owner.sig_members.create(:topic => other_topic, :role => :owner)    
    # he is owner of 2 topics
    users = [User.gen, User.gen]
    users.each do |user|
      MembershipRequest.create(:user_id => user.id, :topic_id => topic.id)
    end
    # more users to 2 topic
    more_users = [User.gen, User.gen, User.gen]
    more_users.each do |user|
      MembershipRequest.create(:user_id => user.id, :topic_id => other_topic.id)
    end
    
    lambda do
      MembershipRequest.daily_notification    
    end.should change(Merb::Mailer.deliveries, :length).by(3)
    
  end
  
  it "should be send only once" do
    users = [User.gen,User.gen]
    users.each do |user|
      MembershipRequest.create(:user_id => user.id, :topic_id => @topic.id)
    end
    
    lambda do
    MembershipRequest.daily_notification    
    end.should change(Merb::Mailer.deliveries, :length).by(2)

    # 2 try
    lambda do
    MembershipRequest.daily_notification    
    end.should change(Merb::Mailer.deliveries, :length).by(0)
    
  end

end