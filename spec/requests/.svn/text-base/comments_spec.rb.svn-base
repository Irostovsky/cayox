require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Comments" do

   before(:each) do
     @user = User.gen
     @topic = Topic.gen
     @topic.add_owner(User.gen)
     @element = Element.gen(:name => { :pl => 'buba' })
     @topic.topic_elements.create(:element => @element)
   end

   it "should add comment to topic" do
     as(@user) do
       response = request("/comments?type=Topic&id=#{@topic.id}", :method => "post", :params => {:comment => "test comment" })
       response.status.should be(302)
       @topic.topic_comments.count.should be(1)
     end
   end
   
   it "should add comment to element" do
     as(@user) do
       response = request("/comments?type=Element&id=#{@element.id}", :method => "post", :params => {:comment => "test comment" })
       response.status.should be(302)
       @element.element_comments.count.should be(1)
     end
   end
   
   it "should display topic comments" do
     as(@user) do
       response = request("/topics/#{@topic.id}")
       response.should be_successful
     end
   end
   
   it "should display element comments" do
     as(@user) do
       response = request("/topics/#{@topic.id}/elements/#{@element.id}")
       response.should be_successful
     end
   end
   
   it "should not create empty comment" do
     as(@user) do
       response = request("/comments?type=Topic&id=#{@topic.id}", :method => "post", :params => {:comment => " " })
       response.status.should be(302)
       @topic.topic_comments.count.should be(0)
     end
   end
  
   it "should not create empty comment" do
     as(@user) do
       response = request("/comments?type=Element&id=#{@element.id}", :method => "post", :params => {:comment => "" })
       response.status.should be(302)
       @element.element_comments.count.should be(0)
     end
   end
  
   it "should not create comment for unlogged user" do
     response = request("/comments?type=Topic&id=#{@topic.id}", :method => "post", :params => {:comment => " comment " })
     response.status.should be(401)
   end
   
   it "should display commnets for topic" do
     as(@user) do
       response = request("/comments/topic_comments?topic_id=#{@topic.id}&page=1")
       response.status.should be_successful
       response = request("/comments/element_comments?element_id=#{@element.id}&page=1")
       response.status.should be_successful
     end
   end

   it "should show 404 if topic has been blocked or removed" do
     topic = Topic.gen
     topic.hide!
     [666, topic.id].each do |topic_id|
       as(@user) do
         response = request(resource(:comments, :type => "Topic", :id => topic_id), :method => "post", :params => {:comment => "comment" })
         response.should be_not_found
       end
     end
   end
  
   it "should show 404 if element has been blocked or removed" do
     topic = Topic.gen
     element = Element.gen
     topic_element = topic.topic_elements.create(:element => element)
     topic_element.hide!
     [666, element.id].each do |element_id|
       as(@user) do
         response = request(resource(:comments, :type => "Element", :id => element_id), :method => "post", :params => {:comment => "comment" })
         response.should be_not_found
       end
     end
   end
end