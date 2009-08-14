require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe ElementVote do

  before(:each) do
    @element = Element.gen
    @user = User.gen
  end

  it "should be able to rate element" do
    @element.vote(5.0,@user)
    @element.reload
    @element.element_votes.first(:user_id => @user.id).rate.should eql(5.0)
  end
  
  it "should update old vote, not create new" do
    lambda { @element.vote(3.0,@user) }.should change(@element.element_votes, :count).by(1)
    @element.reload
    @element.element_votes.first(:user_id => @user.id).rate.should eql(3.0)
    lambda { @element.vote(4.0,@user) }.should change(@element.element_votes, :count).by(0)
    @element.element_votes.first(:user_id => @user.id).rate.should eql(4.0)
  end

  it "should calculate avegare" do
    freaks = [User.gen, User.gen, User.gen, User.gen]
    freaks.each_with_index do |user, index|
      @element.vote(index, user)
    end
    @element.reload
    @element.average_vote.should eql( 2.0 )
  end

  it "should count rank" do
    element = Element.gen
    Topic.gen.topic_elements.create(:element => element)
    element.add_view_by(Guest.new)
    element.rank.should < 1.1
    element.rank.should > 0.9
  end

end