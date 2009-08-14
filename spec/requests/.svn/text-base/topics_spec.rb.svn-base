require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

def valid_topic_hash
  { :name => "IDM Music", :description =>"Intelligent Dance Music", :tag_list => "afx,venetian snares , flashbulb" }
end

describe "Topic" do
  before(:all) do
    prepare_public_topic
    prepare_closed_topic
    prepare_private_topic
    @closed_topic_pending_owner = User.gen
    @closed_topic.sig_members.create(:user => @closed_topic_pending_owner, :role => :owner, :accepted => false)
  end

  describe "creation" do

    before(:all) { Language.gen(:iso_code => "pl") }

    it "should create topic without tags" do
      as(User.gen) do
        response = request("/topics", :method => "post", :params => { :lang => "pl", :topic => valid_topic_hash.merge!(:tag_list => nil) })
        response.body.to_s.should =~ /\/topics\/\d+/ #_to(resource(Topic.first(:name => valid_topic_hash[:name]), :elements, :new))
      end
    end

    it "should create topic with tags" do
      as(User.gen) do
        response = request("/topics", :method => "post", :params => { :topic => valid_topic_hash })
        response.body.to_s.should =~ /\/topics\/\d+/
      end
    end

    it "shouldn't create topic if topic is invalid" do
      as(User.gen) do
        lambda do
          lambda do
            response = request("/topics", :method => "post", :params => { :topic => { :name => "" } })
            response.should be_successful
          end.should_not change(Element, :count)
        end.should_not change(Topic, :count)
      end
    end

    it "should create topic form bookmark" do
      user = User.gen
      bookmarks = [Bookmark.gen(:user_id => user.id),Bookmark.gen(:user_id => user.id)]
      as(user) do
        lambda do
        lambda do
          response = request("/topics", :method => "post", :params => { :topic => valid_topic_hash, :bookmarks => bookmarks.map{|x| x.id}.join(",")  } )
          response.should be_successful
        end.should change(Element, :count).by(2)
        end.should change(Topic, :count).by(1)
      end
    end

  end

  describe "view" do

    it "should contain all elements belonging to a topic" do
      elements = (1..5).map { |i| Element.gen }
      elements.each { |e| @topic.topic_elements.create(:element => e) }

      as(@topic_maintainer) do
        response = request("/topics/#{@topic.id}")
        response.should be_successful
        elements.each do |element|
          response.should have_selector(".element_list li:contains('#{element.name[:pl]}')")
          response.should have_selector(".element_list li:contains('#{element.link.site}')")
        end
      end
    end

    it "should show message if topic is empty" do
      topic = Topic.gen
      topic.add_owner(@topic_owner)
      as(@topic_owner) do
        response = request("/topics/#{topic.id}")
        response.should be_successful
        response.body.should include("No elements")
      end
    end

    it "should show elements when topic is public" do
      [Guest.new, User.gen].each do |user|
        as(user) do
          response = request("/topics/#{@topic.id}")
          response.should be_successful
        end
      end
    end

    it "should show elements when topic is private but user is owner" do
      as(@private_topic_owner) do
        response = request("/topics/#{@private_topic.id}")
        response.should be_successful
      end
    end

    it "should show elements when topic is for closed group but user is owner, maintainer, consumer or site admin" do
      [@closed_topic_owner, @closed_topic_maintainer, @closed_topic_consumer, @closed_topic_pending_owner, User.gen(:admin => true)].each do |user|
        as(user) do
          response = request(resource(@closed_topic))
          response.should be_successful
        end
      end
    end

    it "should show 403 error when topic is private and user don't have rights" do
      [@closed_topic_owner, @closed_topic_maintainer, @closed_topic_consumer, Guest.new, User.gen].each do |user|
        as(user) do
          response = request(resource(@private_topic))
          response.status.should == 403
        end
      end
    end

    it "should show Edit Roles link if topic is non-private for topic owner and admin" do
      [@topic_owner, User.gen(:admin => true)].each do |user|
        as(user) do
          response = request("/topics/#{@topic.id}")
          response.should be_successful
          response.should have_selector("a:contains('Edit Roles')")
        end
      end
    end

    it "shouldn't show Edit Roles link if topic is private" do
      as(@private_topic_owner) do
        response = request(resource(@private_topic))
        response.should be_successful
        response.should_not have_selector("a:contains('Edit Roles')")
      end
    end

    it "shouldn't show Edit Roles and Edit links if user is pending owner" do
      as(@closed_topic_pending_owner) do
        response = request(resource(@closed_topic))
        response.should be_successful
        response.should_not have_selector("a:contains('Edit Roles')")
        response.should_not have_selector("a#edit_topic_link")
      end
    end

    it "should show Flag link for every user" do
      [User.gen, Guest.new].each do |user|
        as(user) do
          response = request(resource(@topic))
          response.should be_successful
          response.should have_selector("a.flag_topic_link")
        end
      end
    end

    it "should show 'Link' link for every user" do
      [User.gen, Guest.new, @topic_owner].each do |user|
        as(user) do
          response = request(resource(@topic))
          response.should be_successful
          response.should have_selector("a#permalink_link")
        end
      end
    end

    it "should show 404 error when topic is hidden" do
      @topic.hide!
      as(@topic_owner) do
        response = request("/topics/#{@topic.id}")
        response.status.should == 404
      end
    end

    it "should be successful after commenting user has been removed" do
      author = User.gen
      @topic.comments.create(:user => author, :body => "choronzonic chaos gods")
      author.remove!
      response = request(resource(@topic))
      response.should be_successful
    end

  end

  describe "visits" do

    it "should be incremented for guests and users not involved in this topic" do
      topic = Topic.gen
      topic.add_owner(User.gen)
      [Guest.new, User.gen, @closed_topic_consumer].each do |user|
        as(user) do
          lambda do
            response = request(resource(topic))
            response.should be_successful
            topic.reload
          end.should change(topic, :views).by(1)
        end
      end
    end

    it "should be incremented for closed topic for consumers" do
      as(@closed_topic_consumer) do
        lambda do
          response = request("/topics/#{@closed_topic.id}")
          response.should be_successful
          @closed_topic.reload
        end.should change(@closed_topic, :views).by(1)
      end
    end

    it "should not be incremented for public topic for owners and maintainers" do
      [@topic_owner, @topic_maintainer].each do |user|
        as(user) do
          lambda do
            response = request("/topics/#{@topic.id}")
            response.should be_successful
            @topic.reload
          end.should_not change(@topic, :views)
        end
      end
    end

    it "should not be incremented for closed topic for owners and maintainers" do
      [@closed_topic_owner, @closed_topic_maintainer].each do |user|
        @closed_topic.reload
        as(user) do
          lambda do
            response = request("/topics/#{@closed_topic.id}")
            response.should be_successful
            @closed_topic.reload
          end.should_not change(@closed_topic, :views)
        end
      end
    end

    it "should not be incremented for private topic for owners" do
      as(@private_topic_owner) do
        lambda do
          response = request("/topics/#{@private_topic.id}")
          response.should be_successful
          @private_topic.reload
        end.should_not change(@private_topic, :views)
      end
    end
  end

  describe "update" do

    it "should not allow other user to update topic" do
      [User.gen, @closed_topic_owner].each do |user|
        as(user) do
          response = request("/topics/#{@private_topic.id}", :method => "put", :params => { :lang => "pl", :topic => { :name => "hacked!" } })
          response.status.should == 403
        end
      end

      [User.gen, @private_topic_owner].each do |user|
        as(user) do
          response = request("/topics/#{@closed_topic.id}", :method => "put", :params => { :lang => "pl", :topic => { :name => "hacked!" } })
          response.status.should == 403
        end
      end
    end

    it "should not allow consumer to update topic" do
      as(@closed_topic_consumer) do
        response = request("/topics/#{@closed_topic.id}", :method => "put", :params => { :lang => "pl", :topic => { :name => "hacked!" } })
        response.status.should == 403
      end
    end

    it "should allow owner or maintainter to update topic" do
      [@closed_topic_owner, @closed_topic_maintainer].each do |user|
        as(user) do
          response = request("/topics/#{@closed_topic.id}", :method => "put", :params => { :lang => "pl", :topic => { :name => "changed!" } })
          response.should be_successful
        end
      end

      as(@private_topic_owner) do
        response = request("/topics/#{@private_topic.id}", :method => "put", :params => { :lang => "pl", :topic => { :name => "changed!" } })
        response.should be_successful
      end
    end

    it "should add bookmarks to topic" do
      bookmark = Bookmark.gen(:user => @topic_owner)
      as(@topic_owner) do
        lambda do
          response = request("/topics/add?bookmarks=#{bookmark.id}", :params => { :topic => @topic.id })
          response.status.should be(302)
        end.should change(Element,:count).by(1)
      end
    end

    it "should add bookmarks only for owner or maintainer" do
      bookmark = Bookmark.gen(:user => @topic_maintainer)
      as(@topic_maintainer) do
        lambda do
          response = request("/topics/add?bookmarks=#{bookmark.id}", :params => { :topic => @topic.id })
          response.status.should be(302)
        end.should change(Element,:count).by(1)
      end
    end

    it "should not work with random user" do
      user = User.gen
      bookmark = Bookmark.gen(:user => user )
      as(user) do
        lambda do
          response = request("/topics/add?bookmarks=#{bookmark.id}", :params => { :topic => @topic.id })
          response.status.should be(302)
        end.should change(Element,:count).by(0)
      end
    end

  end

  describe "voting" do
  
    it "should be able to vote"
   
    it "shouuld be able to change his vote"
    
    it "should be able to cancel vote"

  end

  describe "adopt/abandon" do
   
   before(:each) do
     @topic_owner = User.gen
     @topic = Topic.gen
     @topic.add_owner(@topic_owner)
     @adoptable_topic = Topic.gen
     @adoptable_topic.add_owner(@topic_owner)
     @adoptable_topic.abandoned_at = ( DateTime::now + 1 )
     @adoptable_topic.save
   end
   
    it "should see topics that are adoptable on his profile" do
      as(@topic_owner) do
        response = request("/users/#{@topic_owner.id}/edit")
        response.should be_successful
        response.should have_selector("h2:contains('ADOPTABLE TOPICS')")
      end
    end
    
    it "should adopt topic" do
      user = User.gen
      @adoptable_topic.owners.should_not be_include(user)
      as(user) do
        response = request("/topics/#{@adoptable_topic.id}/adopt")
        response.status.should be(302)
        @adoptable_topic.reload
        @adoptable_topic.owners.should be_include(user)
      end
    end
    
    it "should abandon topic" do
      as(@topic_owner) do
        #abandon normal public topic
        response = request("/topics/#{@topic.id}/abandon")
        response = request(response.headers['Location'])
        response.should have_selector(".notice:contains('adoption')")
        @topic.reload
        @topic.abandoned_at.should_not be_nil
        @topic.owners.should be_include(@topic_owner)
      end
    end
    
    it "should abandon private topic" do
      user = User.gen
      private_topic = Topic.gen(:access_level => :private)
      private_topic.add_owner(user)
      as(user) do
        response = request("/topics/#{private_topic.id}/abandon")
        response.status.should be(302)
        response = request(response.headers['Location'])
        response.should have_selector(".notice:contains('removed')")
        Topic.get(private_topic.id).should be_nil
      end
    end

    it "should correclty adopt for none accepted owner who 'takes lead' after owner of a topic abandon it" do
      user = User.gen
      SigMember.create(:topic_id => @topic.id, :accepted => false, :user_id => user.id)
      as(@topic_owner) do
        response = request("/topics/#{@topic.id}/abandon")
        response.status.should be(302)
      end
      as(user) do
        response = request("/topics/#{@topic.id}/adopt")
        response.status.should be(302)
      end
      @topic.reload
      @topic.owners.should be_include(user)
      @topic.owners.should_not be_include(@topic_owner)
    end

    it "should send mail to both new and old owner of adopted topic" do
      user = User.gen
      as(user) do
        lambda do
          response = request("/topics/#{@adoptable_topic.id}/adopt")
          response.status.should be(302)
        end.should change(Merb::Mailer.deliveries, :length).by(2)
      end
    end 

    it "should swap owners when teaking a lead of topic while being consumer" do
      user = User.gen
      @topic.add_consumer(user)
      as(@topic_owner) do
        response = request("/topics/#{@topic.id}/abandon")
        response.status.should be(302)
      end
      as(user) do
        response = request("/topics/#{@topic.id}/adopt")
        response.status.should be(302)
      end
      @topic.reload
      @topic.owners.should be_include(user)
      @topic.owners.count.should eql(1)
    end

  end

  describe "permalink" do

    it "should be shown without form for guest" do
      as(Guest.new) do
        response = request(resource(@topic, :permalink))
        response.should be_successful
        response.should have_selector("input#permalink")
        response.should_not have_selector("form")
      end
    end

    it "should be shown with form for cayox user" do
      as(User.gen) do
        response = request(resource(@topic, :permalink))
        response.should be_successful
        response.should have_selector("input#permalink")
        response.should have_selector("form")
      end
    end

    it "should be shown without form for private topic owner" do
      as(@private_topic_owner) do
        response = request(resource(@private_topic, :permalink))
        response.should be_successful
        response.should have_selector("input#permalink")
        response.should_not have_selector("form")
      end
    end

    it "shouldn't be shown for private topic and not-owner" do
      as(User.gen) do
        response = request(resource(@private_topic, :permalink))
        response.should be_forbidden
      end
    end

    it "should be send to friend if form is valid" do
      as(User.gen) do
        lambda do
          response = request(resource(@topic, :permalink), :method => 'post', :params => { :permalink_form => { :email => "email@email.com" } })
          response.should be_successful
          response.body.to_s.should == ""
        end.should change(Merb::Mailer.deliveries, :count).by(1)
      end
    end

    it "should not be send to friend if form is invalid" do
      as(User.gen) do
        lambda do
          response = request(resource(@topic, :permalink), :method => 'post', :params => { :permalink_form => { :email => "email" } })
          response.should be_successful
          response.should have_selector("form")
        end.should_not change(Merb::Mailer.deliveries, :count)
      end
    end
  end

end