require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Friendship" do
  
  before(:each) do
    @user = User.gen
    @uo, @ut = User.gen, User.gen
  end
  
  it "should be able to reject friendship" do
    @fr = Friendship.create(:user_id => @uo.id, :friend_id => @ut.id)
    
    as(@ut) do
      response = request("/friends/#{@fr.id}/reject" )
      response.status.should be(404)
    end
  end
  
  it "should be able to accept friendship" do
    @fr = Friendship.create(:user_id => @uo.id, :friend_id => @ut.id)
    
    as(@ut) do
      response = request("/friends/#{@fr.id}/accept" )
      response.status.should be(302)
    end
  end
  
  
  it "should be unable to accept friendship that don't exists" do    
    as(User.gen) do
      response = request("/friends/6677/accept" )
      response.status.should be(302)
    end
  end
  
  
  it "should not be able to manipulate other people friendships" do
    @fr = Friendship.create(:user_id => @uo.id, :friend_id => @ut.id)
    
    as(@user) do
      response = request("/friends/#{@fr.id}/reject" )
      response.status.should be(404)
    end
  end
  
  it "should display friends" do
    as(@user) do
      response = request("/friends" )
      response.should be_successful
    end
  end
  
  it "should invite new friend" do
    as(@user) do
      lambda do
        response = request("/friends", :method => "post", :params => { :invitation_form => {:email => "das@email.de"} } )
        response.status.should be(302)
      end.should change(Merb::Mailer.deliveries, :count).by(2)
    end
  end
  
  it "should render info on error" do
    as(@user) do
      response = request("/friends", :method => "post", :params => { :invitation_form => {:email => ""} } )
      response.should have_selector("span.error")
      response.status.should be(200)
      response = request("/friends", :method => "post", :params => { :invitation_form => {:email => "invalid_email"} } )
      response.should have_selector("span.error")
      response.status.should be(200)
    end
  end
  
  it "should render error when user invites 2 time someone" do
    as(@user) do
      response = request("/friends", :method => "post", :params => { :invitation_form => {:email => "test@email.com"} } )
      response = request("/friends", :method => "post", :params => { :invitation_form => {:email => "test@email.com"} } )
      response.should have_selector("span.error")
      response.status.should be(200)
    end
  end
  
  it "should join friends if they both invite them selfs and then accept" do
    other_user = User.gen
    as(@user) do
      response = request("/friends", :method => "post", :params => { :invitation_form => {:email => other_user.email } } )
    end
    as(other_user) do
      response = request("/friends", :method => "post", :params => { :invitation_form => {:email => @user.email } } )
      fr = Friendship.first(:user_id => @user.id, :friend_id => other_user.id)
      response = request("/friends/#{fr.id}/accept")
      response.status.should be(302)
    end
    fr = Friendship.first(:user_id => @user.id, :friend_id => other_user.id)
    fr.should be_accepted
    fr2 = Friendship.first(:user_id => other_user.id, :friend_id => @user.id)
    fr2.should be_accepted
  end
  
  it "should not inivte already existing friend" do
    friend = User.gen
    Friendship.create(:user_id => @user.id, :friend_id => friend.id, :accepted => true)
    Friendship.create(:user_id => friend.id, :friend_id =>  @user.id, :accepted => true)
    as(@user) do
      response = request("/friends", :method => "post", :params => { :invitation_form => {:email => friend.email } } )
      response.status.should be(200)
      response.should have_selector("span.error")
    end
  end
  
  it "should display form where user can invite friend" do
    as(@user) do
      response = request(resource(:friends,:new))
      response.should be_successful
    end
  end
  
end
