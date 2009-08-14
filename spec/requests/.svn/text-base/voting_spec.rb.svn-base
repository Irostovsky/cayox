require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Voting" do
  
  it "should be able to vote" do
    user = User.gen
    element = Element.gen
    as(user) do
      response = request("/voting/create", :method => "post", :params => { :element_id => element.id, :rate => "5" } )
    end
    
    element.reload
    element.average_vote.should == 5.0
    
  end
  
end