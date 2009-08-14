require File.join( File.dirname(__FILE__), '..', "spec_helper" )

def valid_topic_hash
  { :name => { :pl => "IDM Music" }, :description => { :pl => "Intelligent Dance Music" }, :tag_list => "afx,venetian snares , flashbulb" }
end

describe Topic do

  it "should validate uniqueness of name"

  it "should remove malicious code upon creation" do
    topic = Topic.gen(:name => { "pl" => '<script>alert("o men!")</script>Topic name' })
    topic.should be_valid
    topic.name["pl"].should include('Topic name')
    topic.name["pl"].should_not include('<script>')
    topic.name["pl"].should_not include('</script>')
  end

  it "should be able to create comment" do
    user = User.gen
    topic = Topic.gen
    comment = topic.topic_comments.new(:user_id => user.id)
    comment.body = "test"
    comment.save
    topic.topic_comments.count.should be(1)
    topic.topic_comments[0].body.should eql("test")
  end
  
  it "shouldn't be created with description longer than 1024 characters" do
    topic = Topic.make(:description => { "pl" => "A" * 1025 })
    topic.should_not be_valid
    topic.errors.on(:description).should_not be_empty
  end

  it "shouldn't be created with invalid tags" do
    topic = Topic.make(:tag_list => "A" * 51)
    topic.should_not be_valid
    topic.errors.on(:tag_list).should_not be_empty
  end

  it "shouldn't allow to change access level to private if it has users assigned" do
    # topic with one owner, no other members
    topic = Topic.gen(:access_level => :public)
    topic.access_level = :private
    topic.save
    topic.should_not be_dirty

    # topic with two owners, one maintainer
    topic = Topic.gen(:access_level => :public)
    topic.add_owner(User.gen)
    topic.add_maintainer(User.gen)
    topic.access_level = :private
    topic.save
    topic.should be_dirty
    topic.errors.on(:access_level).should_not be_empty
  end

  describe "update" do

    it "should not send email (regression test for DM bug)" do
      topic = Topic.gen
      topic.add_owner(User.gen)
      topic = Topic.get(topic.id)
      lambda do
        topic.update_attributes(:access_level => :private)
      end.should_not change(Merb::Mailer.deliveries, :count)
    end

  end

  describe "with tags" do

    it "should be created with tag list longer than 50 characters" do
      topic = Topic.gen(:tag_list => (0..100).map { |i| "tag#{i}" }.join(","))
      topic.should be_valid
    end

    it "shouldn't be created with tag list longer than 1024 characters" do
      topic = Topic.gen(:tag_list => (0..500).map { |i| "tag#{i}" }.join(","))
      topic.should_not be_valid
      topic.errors.on(:tag_list).should_not be_empty
    end

    it "should remove one tag" do
      topic = Topic.gen(:tag_list => "tag1, tag2, tag3")
      topic.should be_valid
      topic.topic_tags.should_not be_empty
      topic = Topic.get(topic.id)
      topic.tags.should_not be_empty

      topic.update_attributes(:tag_list => "tag1, tag2")
      topic = Topic.get(topic.id)
      topic.tags.size.should == 2
    end

    it "should remove all tags when empty string as tag_list is given" do
      topic = Topic.gen(:tag_list => "tag1, tag2, tag3")
      topic.should be_valid
      topic.topic_tags.should_not be_empty
      topic = Topic.get(topic.id)
      topic.tags.should_not be_empty

      topic.update_attributes(:tag_list => "")
      topic = Topic.get(topic.id)
      topic.tags.should be_empty
    end

  end

  it "should update tag_count after update/create" do
    Topic.gen(:tag_list => "").tag_count.should == 0
    topic = Topic.gen(:tag_list => "tag1, tag2, tag3")
    topic.tag_count.should == 3

    topic.tag_list = "tag1"
    topic.save
    topic.tag_count.should == 1
  end

  it "should remove taggings upon removal" do
    topic = Topic.gen(:tag_list => "tag1, tag2, tag3")
    lambda do
      topic.destroy
    end.should change(TopicTag, :count).by(-3)
  end

  describe "fetching" do

    it "should fetch only visible topics in Topic.all" do
      lambda do
        lambda do
          3.times { Topic.gen }
          2.times { Topic.gen.hide! }
        end.should change(Topic.all, :count).by(3)
      end.should change(Topic.all_without_scope, :count).by(5)
    end

    it "should fetch only visible topics in user.topics" do
      user = User.gen
      # 3 visible
      2.times { Topic.gen.add_owner(user) }
      Topic.gen.add_maintainer(user)
      # 2 hidden
      t = Topic.gen
      t.add_owner(user)
      t.hide!
      t = Topic.gen
      t.add_consumer(user)
      t.hide!
      user.topics.count.should == 3
    end

    it "should fetch only visible topics in user.owned_topics" do
      user = User.gen
      2.times { Topic.gen.add_owner(user) }
      3.times { t = Topic.gen; t.add_owner(user); t.hide! }
      user.owned_topics.count.should == 2
    end

    it "should fetch only visible topics in user.maintained_topics" do
      user = User.gen
      2.times { Topic.gen.add_maintainer(user) }
      3.times { t = Topic.gen; t.add_maintainer(user); t.hide! }
      user.maintained_topics.count.should == 2
    end

    it "should fetch only visible topics in user.consumed_topics" do
      user = User.gen
      2.times { Topic.gen.add_consumer(user) }
      3.times { t = Topic.gen; t.add_consumer(user); t.hide! }
      user.consumed_topics.count.should == 2
    end

    it "should fetch only visible topics in user.editable_topics" do
      user = User.gen
      1.times { Topic.gen.add_owner(user) }
      2.times { t = Topic.gen; t.add_owner(user); t.hide! }
      3.times { Topic.gen.add_maintainer(user) }
      4.times { t = Topic.gen; t.add_maintainer(user); t.hide! }
      user.editable_topics.count.should == 4
    end
  end

  describe "search" do

    describe "for given tags" do

      before(:all) do
        Topic.all.destroy!
        @owner = User.gen
        Topic.gen(:tag_list => "foo")
        Topic.gen(:tag_list => "foo, bar")
        Topic.gen(:tag_list => "foo, bar, baz").add_consumer(User.gen)
        Topic.gen(:tag_list => "baz", :access_level => :closed_user_group)
        Topic.gen(:tag_list => "foo", :access_level => :private).add_owner(@owner)
        Topic.gen(:tag_list => "foo, bar", :access_level => :private).add_owner(User.gen)
        Topic.gen(:tag_list => "private, baz", :access_level => :private).add_owner(@owner)
        t = Topic.gen(:tag_list => "foo, bar, baz")
        t.add_owner(@owner)
        t.hide!
      end
      
      it "should find topics without user" do
        Topic.search([])[1].size.should == 7
        Topic.search([Tag["foo"]])[1].size.should == 5
        Topic.search([Tag["bar"], Tag["foo"]])[1].size.should == 3
        Topic.search([Tag["bar"], Tag["foo"], Tag["baz"]])[1].size.should == 1
        Topic.search([Tag["baz"]])[1].size.should == 3
      end
      
      it "should find topics for guest" do
        Topic.search([Tag["foo"]], :user => Guest.new)[1].size.should == 3
        Topic.search([Tag["bar"], Tag["foo"]], :user => Guest.new)[1].size.should == 2
        Topic.search([Tag["bar"], Tag["foo"], Tag["baz"]], :user => Guest.new)[1].size.should == 1
        Topic.search([Tag["baz"]], :user => Guest.new)[1].size.should == 2
      end

      it "should find topics for owner" do
        Topic.search([Tag["foo"]], :user => @owner)[1].size.should == 4
        Topic.search([Tag["bar"], Tag["foo"]], :user => @owner)[1].size.should == 2
        Topic.search([Tag["bar"], Tag["foo"], Tag["baz"]], :user => @owner)[1].size.should == 1
        Topic.search([Tag["baz"]], :user => @owner)[1].size.should == 3
      end

      it "should find topics for other user" do
        Topic.search([Tag["baz"]], :user => User.gen)[1].size.should == 2
      end

      it "should return paginated results" do
        Topic.search([Tag["foo"]], :per_page => 4, :page => 1)[1].size.should == 4
        Topic.search([Tag["foo"]], :per_page => 4, :page => 2)[1].size.should == 1
      end

      it "should find topics in My Topics" do
        Topic.search([Tag["foo"]], :user => @owner, :users_topics_only => true)[1].size.should == 1
      end

    end

    it "should fetch views property" do
      Topic.all.destroy!
      # Topic#find_by_sql breaks while iterating on resultset when order of properties is wrong!
      # We need to check if iteration over results set works correctly.
      # If no, check order of fields fetched in Topic#search_query and Topic#search
      Topic.gen(:tag_list => "dhg", :views => 666)
      page_count, topics = Topic.search([])
      topics.each do |topic|
        topic.views.should == 666
      end
    end

    it "should sort results by tags count (then by visits) when tags provided" do
      Topic.all.destroy!
      
      topic1 = Topic.gen(:tag_list => "foo, bar, baz", :views => 500)
      topic2 = Topic.gen(:tag_list => "foo, bar", :views => 100)
      topic3 = Topic.gen(:tag_list => "foo")
      topic4 = Topic.gen(:tag_list => "foo, jola", :views => 99)

      page_count, topics = Topic.search([Tag["foo"]])
      topics.size.should == 4
      topics[0].should == topic3
      topics[1].should == topic2
      topics[2].should == topic4
      topics[3].should == topic1
    end

    it "should show also topics without tags and sort results by visits count (descending) when no tags provided" do
      Topic.all.destroy!

      topic1 = Topic.gen(:views => 123)
      topic2 = Topic.gen(:views => 500)
      topic3 = Topic.gen(:views => 10)

      page_count, topics = Topic.search([])
      topics.size.should == 3
      topics[0].should == topic2
      topics[1].should == topic1
      topics[2].should == topic3
    end

    it "should include only hidden topics if requested" do
      Topic.all_without_scope.destroy!
      Topic.gen
      Topic.gen.hide!
      Topic.gen.hide!
      page_count, topics = Topic.search([], :hidden => true)
      topics.size.should == 2
    end

  end

  describe "hiding" do

    it "should change topic status to hidden, remove element_propositions and fresh elements in favourites" do
      topic = Topic.gen
      favourite = Favourite.create_from_topic(topic, User.gen)
      favourite.add_custom_element(Element.gen).propose!
      favourite.add_custom_element(Element.gen).propose!
      topic.topic_elements.create(:element => Element.gen)
      favourite.synchronize
      topic.status.should == :visible
      lambda do
        lambda do
          topic.hide!
        end.should change(ElementProposition, :count).by(-2)
      end.should change(FavouriteElement.fresh, :count).by(-1)
      topic.status.should == :hidden
    end
  end

  describe "removing abandoned topics" do
  
    it "should destroy out dated abandoned topics from system" do
      [Topic.gen(:abandoned_at => (DateTime::now() - 21) ), Topic.gen(:abandoned_at => (DateTime::now - 11) )]
      lambda do 
        Topic.clear_abandoned
      end.should change(Topic, :count).by(-2)
    end
    
  end

  describe "removal" do

    before(:each) do
      @topic = Topic.gen
      @element = Element.gen(:tag_list => "tag1, tag2, tag3")
      @topic_element = @topic.topic_elements.create(:element => @element)
    end

    it "should be successful" do
      @topic.remove!.should be_true
    end

    it "should remove all related objects" do
      @topic.add_owner(User.gen)
      @topic.add_maintainer(User.gen)
      @topic.add_consumer(User.gen)
      user = User.gen
      2.times { @topic.comments.create(:body => "foo!", :user => user) }
      2.times { @element.comments.create(:body => "foo!", :user => user) }
      3.times { @element.vote(3, User.gen) }
      2.times do
        f = Favourite.create_from_topic(@topic, User.gen)
        f.add_custom_element(Element.gen).propose!
      end
      @topic.topic_flags.create(:flag => Flag.gen, :user => user)
      @topic.membership_requests.create(:user => user)
      @topic.vote(4, User.gen)

      lambda do
        lambda do
          lambda do
            lambda do
              lambda do
                lambda do
                  lambda do
                    lambda do
                      lambda do
                        lambda do
                          lambda do
                            lambda do
                              lambda do
                                @topic.remove!
                              end.should change(Topic.all_without_scope, :count).by(-1)
                            end.should change(TopicComment, :count).by(-2)
                          end.should change(TopicElement, :count).by(-1)
                        end.should change(SigMember, :count).by(-3)
                      end.should change(Favourite, :count).by(-2)
                    end.should change(ElementComment, :count).by(-2)
                  end.should change(ElementProposition, :count).by(-2)
                end.should change(MembershipRequest, :count).by(-1)
              end.should change(TopicFlag, :count).by(-1)
            end.should change(TopicVote, :count).by(-1)
          end.should change(ElementVote, :count).by(-3)
        end.should change(Element, :count).by(-3)
      end.should change(FavouriteElement, :count).by(-4)
    end

  end

end