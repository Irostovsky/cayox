require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Element do
  before(:all) do
    @user = User.gen
  end

  it "should be valid with proper name and url" do
    element = Element.new(:name => { :pl => "ela" }, :url => "http://ela.com.pl/hela")
    element.should be_valid
  end

  it "shouldn't be valid with empty name" do
    element = Element.new(:name => { :pl => "" }, :url => "http://ela.com.pl/hela")
    element.should_not be_valid
    element.errors.on(:name).should_not be_empty
  end

  it "shouldn't be created with description longer than 1024 characters" do
    element = Element.make(:description => { "pl" => "A" * 1025 })
    element.should_not be_valid
    element.errors.on(:description).should_not be_empty
  end

  it "shouldn't be created with tag list longer than 1024 characters" do
    element = Element.gen(:tag_list => (0..500).map { |i| "tag#{i}" }.join(","))
    element.should_not be_valid
    element.errors.on(:tag_list).should_not be_empty
  end

  it "should have url getter" do
    url = "http://ela.com.pl/kaszalot"
    element = Element.new(:name => { :pl => "ela" }, :url => url)
    element.should be_valid
    element.url.should == url

    element.save
    element = Element.get(element.id)
    element.url.should == url
  end
  
  it "should reuse existing links" do
    lambda { Element.create(:name => { :en => "Elo 1" }, :url => "http://ela.com.pl/hela").should be_valid }.should change(Link, :count).by(1)
    lambda { Element.create(:name => { :pl => "Elaaaaa" }, :url => " http://ela.com.pl/hela ").should be_valid }.should_not change(Link, :count)
  end

  it "should be able to create comment" do
    user = User.gen
    element = Element.gen
    comment = element.element_comments.new(:user_id => user.id)
    comment.body = "test"
    comment.save
    element.element_comments.count.should be(1)
    element.element_comments[0].body.should eql("test")
  end

  describe "search" do

    it "should find elements for given topic and tags" do
      owner = User.gen

      # some other public topic
      some_topic = Topic.gen
      some_topic.add_owner(owner)
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "some"))
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "some, topic"))
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "some, topic, tag"))
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "some, topic, tag, removed"), :status => :removed)
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "some, topic, tag, hidden"), :status => :hidden)

      # some private topic
      some_topic = Topic.gen(:access_level => :private)
      some_topic.add_owner(owner)
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "private"))
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "private, topic"))
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "private, topic, tag"))
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "private, topic, tag, removed"), :status => :removed)
      some_topic.topic_elements.create(:element => Element.gen(:tag_list => "private, topic, tag, hidden"), :status => :hidden)

      # THIS topic
      the_topic = Topic.gen
      the_topic.add_owner(owner)
      the_topic.topic_elements.create(:element => Element.gen(:tag_list => "boo"))
      the_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo"))
      the_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo, bar, topic"))
      the_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo, bar, baz"))
      the_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo, bar, baz, removed"), :status => :removed)
      the_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo, bar, baz, hidden"), :status => :hidden)

      # let's test
      page_count, elements = Element.search([], :topic => the_topic)
      elements.size.should == 4
      page_count, elements = Element.search([Tag["foo"]], :topic => the_topic)
      elements.size.should == 3
      page_count, elements = Element.search([Tag["bar"], Tag["foo"]], :topic => the_topic)
      elements.size.should == 2
      page_count, elements = Element.search([Tag["bar"], Tag["foo"], Tag["baz"]], :topic => the_topic)
      elements.size.should == 1
      page_count, elements = Element.search([Tag["topic"]], :topic => the_topic)
      elements.size.should == 1

      # pagination
      page_count, elements = Element.search([Tag["foo"]], :topic => the_topic, :per_page => 2, :page => 1)
      page_count.should == 2
      elements.size.should == 2

      page_count, elements = Element.search([Tag["foo"]], :topic => the_topic, :per_page => 2, :page => 2)
      page_count.should == 2
      elements.size.should == 1

      page_count, elements = Element.search([Tag["foo"]], :topic => the_topic, :per_page => 1)
      page_count.should == 3
      elements.size.should == 1
    end

    it "should find elements for topic when elements have no tags" do
      topic = Topic.gen
      topic.topic_elements.create(:element => Element.gen(:tag_list => ""))
      topic.topic_elements.create(:element => Element.gen(:tag_list => ""))
      topic.topic_elements.create(:element => Element.gen(:tag_list => ""))
      topic.topic_elements.create(:element => Element.gen(:tag_list => ""), :status => :removed)
      page_count, elements = Element.search([], :topic => topic)
      elements.size.should == 3
    end

    it "should not include removed elements" do
      topic = Topic.gen
      topic.topic_elements.create(:element => Element.gen)
      topic.topic_elements.create(:element => Element.gen)
      favourite = Favourite.create_from_topic(topic, User.gen)
      page_count, elements = Element.search([], :favourite => favourite)
      elements.size.should == 2
      favourite.favourite_elements.first.remove!
      page_count, elements = Element.search([], :favourite => favourite)
      elements.size.should == 1
    end

    it "should return only hidden elements if requested" do
      topic = Topic.gen
      topic.topic_elements.create(:element => Element.gen)
      topic.topic_elements.create(:element => Element.gen).hide!
      topic.topic_elements.create(:element => Element.gen).hide!
      page_count, elements = Element.search([], :topic => topic, :hidden => true)
      elements.size.should == 2
    end
  end

  describe "removal" do
    before(:each) do
      @topic = Topic.gen
      @element = Element.gen(:tag_list => "tag1, tag2, tag3")
      @topic_element = @topic.topic_elements.create(:element => @element)
    end

    it "should remove taggings upon removal" do
      lambda do
        @element.destroy
      end.should change(ElementTag, :count).by(-3)
    end

    it "should be successful" do
      @topic_element.remove!.should be_true
    end

    it "should remove all related objects" do
      user = User.gen
      2.times { @element.comments.create(:body => "foo!", :user => user) }
      3.times { @element.vote(3, User.gen) }
      2.times { Favourite.create_from_topic(@topic, User.gen) }
      @topic_element.topic_element_flags.create(:flag => Flag.gen, :user => user)

      lambda do
        lambda do
          lambda do
            lambda do
              lambda do
                lambda do
                  @topic_element.remove!(true)
                end.should change(TopicElement, :count).by(-1)
              end.should change(TopicElementFlag, :count).by(-1)
            end.should change(ElementComment, :count).by(-2)
          end.should change(ElementVote, :count).by(-3)
        end.should change(Element, :count).by(-1)
      end.should change(FavouriteElement, :count).by(-2)
    end

  end

end