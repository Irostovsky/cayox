require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Search" do

  before(:all) do
    @foo_topics = []
    @foo_topics << Topic.gen(:tag_list => "foo")
    @foo_topics << Topic.gen(:tag_list => "foo, bar")
    @foo_topics << Topic.gen(:tag_list => "foo, bar, baz", :access_level => :closed_user_group)
    @topics = []
    @topics << Topic.gen(:tag_list => "jola, misio")
    @topics << Topic.gen(:tag_list => "marcin, marta, michal, blanka")
    @topics << Topic.gen(:tag_list => "marcin, staszek, krysia")
    @topics << Topic.gen(:tag_list => "marta, staszek, krysia")
    @topics << Topic.gen(:tag_list => "michal, staszek, krysia")
    @topics << Topic.gen(:tag_list => "tomek, staszek, krysia")
    @topics << Topic.gen(:tag_list => "blanka, rysiek, grazynka, mateusz, tadeusz")
    @topics << Topic.gen(:tag_list => "marcin, blanka, staszek, rysiek")
    @topics << Topic.gen(:tag_list => "marcin, blanka, krysia, grazynka")
    @topics.each { |t| t.reload }
    @foo_tags = @foo_topics.inject([]) { |acc, t| acc += t.tags }.uniq
    Topic.gen(:tag_list => "foo, ziom, ochrona", :name => { :pl  => 'Prv' }, :access_level => :private) # shouldn't show in results
  end
  
  describe "for topics" do

    it "should show results if topics found" do
      as(Guest.new) do
        response = request("/search", :params => { :tags => ["foo"] })
        response.should be_successful
        @foo_topics.each do |topic|
          response.should have_selector("ul.topic_list a:contains('#{topic.name["pl"]}')")
        end
        response.should_not have_selector("ul.topic_list a:contains('Prv')")
      end
    end

    it "should show results if private topics found and user is owner" do
      owner = User.gen
      topic = Topic.gen(:access_level => :private, :tag_list => "so secret")
      topic.sig_members.create(:user => owner, :role => :owner)

      as(owner) do
        response = request("/search", :params => { :tags => ["so secret"] })
        response.should be_successful
        response.should have_selector("ul.topic_list a:contains('#{topic.name["pl"]}')")
        response.should_not have_selector("ul.topic_list a:contains('Prv')")
      end
    end

    it "should should results with empty tag cloud if all tags are selected" do
        topic = Topic.gen(:tag_list => "jola, misio, ochronislaw")
        as(Guest.new) do
          response = request("/search", :params => { :tags => ["jola", "misio", "ochronislaw"] })
          response.should be_successful
          response.should have_selector("ul.topic_list a:contains('#{topic.name["pl"]}')")
        end
    end

    it "should show first page of results if page parameter < 1" do
      as(User.gen) do
        [0, -1, -5].each do |n|
          response = request("/search", :params => { :tags => ["foo"], :page => n })
          response.should be_successful
          @foo_topics.each do |topic|
            response.should have_selector("ul.topic_list a:contains('#{topic.name["pl"]}')")
          end
        end
      end
    end

    it "should show all tags assigned to matching topics" do
      tag = Tag["foo"]
      as(Guest.new) do
        response = request("/search", :params => { :tags => [tag.name] })
        response.should be_successful
        response.should have_selector(".selected_tags a:contains('#{tag.name}')")
        (@foo_tags - [tag]).each do |t|
          response.should have_selector(".tag-cloud a:contains('#{t.name}')")
        end
      end
    end

    it "should paginate results according to user's settings" do
      tag = Tag["foo"]
      as(User.gen(:search_results_per_page => 1)) do
        (0..2).each do |n|
          response = request("/search", :params => { :tags => [tag.name], :page => n })
          response.should be_successful
          response.should have_selector(".selected_tags a:contains('#{tag.name}')")
          (@foo_tags - [tag]).each do |t|
            response.should have_selector(".tag-cloud a:contains('#{t.name}')")
          end
        end
      end
    end

    it "should show all topics when no tags are given or no topics found" do
      as(Guest.new) do
        response = request("/search", :params => { :tags => [""] })
        response.should be_successful
        response.should have_selector(".primary:contains('Please filter')")
        response.should have_selector(".topic_list li a")

        response = request("/search")
        response.should be_successful
        response.should have_selector(".primary:contains('Please filter')")
        response.should have_selector(".topic_list li a")

        response = request("/search", :params => { :tags => ["nonexistent_tag"] })
        response.should be_successful
        response.should have_selector(".primary:contains('Please filter')")
        response.should have_selector(".topic_list li a")
      end
    end

    it "should show all topics when given tag is assigned to private topic only" do
      topic = Topic.gen(:tag_list => "secret", :access_level => :private)
      topic.sig_members.create(:user => User.gen, :role => :owner)
      
      [Guest.new, User.gen].each do |user|
        as(user) do
          response = request("/search", :params => { :tags => ["secret"] })
          response.should be_successful
          response.should_not have_selector(".selected_tags a:contains('secret')")
          response.should have_selector(".primary:contains('Please filter')")
          response.should have_selector(".topic_list li a")
        end
      end
    end

  end

  describe "for my topics" do

    it "should raise unathenticated if user is guest" do
      ["/mytopics", "/mytopics?tags[]=abc"].each do |url|
        response = request(url)
        response.status.should == 401
      end
    end

    it "should be successfull for logged in user" do
      as(User.gen) do
        ["/mytopics", "/mytopics?tags[]=abc"].each do |url|
          response = request(url)
          response.should be_successful
        end
      end
    end

    it "shouldn't include closed topic for which user didn't accept ownership role" do
      user = User.gen
      topic = Topic.gen(:name => { :pl => "not-accepted" }, :access_level => :closed_user_group, :tag_list => "not, accepted")
      topic.sig_members.create(:user => user, :role => :owner, :accepted => false)

      as(user) do
        [["not"], []].each do |tags|
          response = request(url(:mytopics), :params => { :tags => tags })
          response.should be_successful
          response.should_not have_selector("ul.topic_list a:contains('not-accepted')")
        end
      end
    end
    
    it "should show propositions and flags info" do
      user = User.gen
      topic = Topic.gen
      topic.add_owner(user)
      topic.topic_flags.create(:flag_id => Flag.gen.id, :user_id => User.gen.id)
      fav = Favourite.create_from_topic(topic, User.gen)
      custom_element = fav.add_custom_element(Element.gen)
      custom_element.propose!
      as(user) do
        response = request(url(:mytopics))
        response.should be_successful
        response.should have_selector("p:contains('element propositions')")
        response.should have_selector("p:contains('flagged items')")
      end
    end
  end

  describe "for elements" do

    it "should show all tags assigned to matching elements" do
      topic = Topic.gen
      topic.add_owner(User.gen)
      topic.topic_elements.create(:element => Element.gen(:tag_list => "tag1, tag2"))
      response = request("/topics/#{topic.id}")
      response.should be_successful
      response.should have_selector(".tag-cloud a:contains('tag1')")
      response.should have_selector(".tag-cloud a:contains('tag2')")
    end

  end

  describe "autosuggestion" do
  
    it "should show autosuggestion for topic tags when there are some matches (first search - no context)" do
      as(Guest.new) do
        response = request("/search/tags_autocomplete", :params => { :q => "f" })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 1
        "foo".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "b" })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 3
        "bar".should be_in(tags)
        "baz".should be_in(tags)
        "blanka".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "t" })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 2
        "tomek".should be_in(tags)
        "tadeusz".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "mar" })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 2
        "marta".should be_in(tags)
        "marcin".should be_in(tags)
      end
    end

    it "shouldn't show autosuggestion for topic tags when there aren't any matches (first search - no context)" do
      as(Guest.new) do
        ["rutowicz", "", "%", "%oo"].each do |keyword|
          response = request("/search/tags_autocomplete", :params => { :q => keyword })
          response.should be_successful
          response.body.to_s.should == ""
        end
      end
    end

    it "should show autosuggestion for topic tags when there are some matches (filtering - with context)" do
      as(Guest.new) do
        response = request("/search/tags_autocomplete", :params => { :q => "marc", :tags => ["marcin"] })
        response.should be_successful
        response.body.to_s.should == ""

        response = request("/search/tags_autocomplete", :params => { :q => "mar", :tags => ["marcin"] })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 1
        "marta".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "m", :tags => ["marcin"] })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 2
        "marta".should be_in(tags)
        "michal".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "mar", :tags => ["krysia"] })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 2
        "marta".should be_in(tags)
        "marcin".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "m", :tags => ["krysia"] })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 3
        "marta".should be_in(tags)
        "marcin".should be_in(tags)
        "michal".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "t", :tags => ["krysia"] })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 1
        "tomek".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "t", :tags => ["grazynka"] })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 1
        "tadeusz".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "ma", :tags => ["blanka"] })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 3
        "marcin".should be_in(tags)
        "marta".should be_in(tags)
        "mateusz".should be_in(tags)

        response = request("/search/tags_autocomplete", :params => { :q => "ma", :tags => ["blanka", "staszek", "rysiek"] })
        response.should be_successful
        tags = response.body.to_s.split("\n")
        tags.size.should == 1
        "marcin".should be_in(tags)
      end
    end

    it "shouldn't show autosuggestion for topic tags when there aren't any matches (filtering - with context)" do
      as(Guest.new) do
        response = request("/search/tags_autocomplete", :params => { :q => "rutowicz", :tags => ["blanka"] })
        response.should be_successful
        response.body.to_s.should == ""

        response = request("/search/tags_autocomplete", :params => { :q => "ochr", :tags => ["marcin"] })
        response.should be_successful
        response.body.to_s.should == ""
      end
    end

    it "should show autosuggestion for element tags"
    it "should show autosuggestion for favourite tags"

  end

end
