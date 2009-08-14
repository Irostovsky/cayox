require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe TopicVote do

  before(:each) do
    @topic = Topic.gen
    @user = User.gen
  end

  it "should be able to rate topic" do
    @topic.vote(5.0, @user)
    @topic.reload
    @topic.topic_votes.first(:user_id => @user.id).rate.should eql(5.0)
  end
  
  it "should update old vote, not create new" do
    lambda { @topic.vote(3.0,@user) }.should change(@topic.topic_votes, :count).by(1)
    @topic.reload
    @topic.topic_votes.first(:user_id => @user.id).rate.should eql(3.0)
    lambda { @topic.vote(4.0,@user) }.should change(@topic.topic_votes, :count).by(0)
    @topic.topic_votes.first(:user_id => @user.id).rate.should eql(4.0)
  end

  it "should calculate average" do
    freaks = [User.gen, User.gen, User.gen, User.gen]
    freaks.each_with_index do |user, index|
      @topic.vote(index, user)
    end
    @topic.reload
    @topic.average_vote.should eql( 2.0 )
  end

  it "should recount topic average vote" do
    user1 = User.gen
    user2 = User.gen
    @topic.vote(2, user1)
    @topic.reload
    @topic.average_vote.to_i.should == 2
    @topic.vote(4, user2)
    @topic.reload
    @topic.average_vote.to_i.should == 3
    user2.remove!
    @topic.reload
    @topic.average_vote.to_i.should == 2
  end

end