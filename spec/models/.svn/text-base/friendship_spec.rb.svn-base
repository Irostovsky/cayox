require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Friendship do

  #uo = user_one
  #ut = user_two

  before(:each) do
    @uo, @ut = User.gen, User.gen
    @fr = Friendship.create(:user_id => @uo.id, :friend_id => @ut.id)
    @fr.accepted.should be_false
  end

  it "should be unique" do
    fr = Friendship.new(:user_id => @uo.id, :friend_id => @ut.id)
    fr.should_not be_valid  
  end 
  
  it "should have user and his friend" do
    fr = Friendship.new
    fr.should_not be_valid
  end

  it "should have pending friendships" do
    @uo.pending_friendships.should_not be_blank
    @uo.pending_friendships.count.should be(1)
  end

  it "should be able to accept friendship" do
    lambda do
      lambda do
        @fr.accept!
      end.should change(FriendshipRequestNotification, :count).by(-1)
    end.should change(@ut.notifications, :count).by(-1)
    @uo.friendships.first(:friend_id => @ut.id).should_not be_nil
    @ut.friendships.first(:friend_id => @uo.id).should_not be_nil
  end

  it "should be able to cancel friendship" do
    @fr.accept!
    @fr.cancel!
    @uo.pending_friendships.should be_blank
    @ut.pending_friendships.should be_blank
  end

  it "should be able to reject friendship" do
    @ut.requested_friendships.should_not be_blank
    @uo.pending_friendships.should_not be_blank
    lambda do
      lambda do
        @fr.reject
      end.should change(FriendshipRequestNotification, :count).by(-1)
    end.should change(@ut.notifications, :count).by(-1)
    @uo.requested_friendships.should be_blank
    @ut.pending_friendships.should be_blank
  end

  it "should not be able make friendship with self" do
    @user = User.gen
    lambda { Friendship.create(:user_id => @user.id, :friend_id => @user.id) }.should change(Friendship, :count).by(0)
  end

  it "should send email upon creation" do
    u1 = User.gen
    u2 = User.gen
    friendship = nil
    lambda do
      friendship = Friendship.create(:user_id => u1.id, :friend_id => u2.id)
    end.should change(Merb::Mailer.deliveries, :count).by(1)
    lambda do
      friendship.accept!
    end.should_not change(Merb::Mailer.deliveries, :count)
  end
  
end
