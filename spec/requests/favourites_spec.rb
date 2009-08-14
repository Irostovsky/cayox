require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

def prepare_fav
  @favourite_owner = User.gen
  topic = Topic.gen
  topic.topic_elements.create(:element => Element.gen(:tag_list => "some, tag, and, another, one"))
  topic.topic_elements.create(:element => Element.gen(:tag_list => "this, is, also, a, tag, and, this, one, is, better"))
  @favourite = Favourite.create_from_topic(topic, @favourite_owner)
end

describe "Favourite creation" do

  before(:all) do
    @topic = Topic.gen(:access_level => :public, :name => { "pl" => "polska nazwa", "en" => "english name", "de" => "deutsche name" })
    @closed_topic = Topic.gen(:access_level => :closed_user_group)
    @closed_topic_owner = User.gen
    @closed_topic_owner.sig_members.create(:topic => @closed_topic, :role => :owner)
    @closed_topic_maintainer = User.gen
    @closed_topic_maintainer.sig_members.create(:topic => @closed_topic, :role => :maintainer)
    @closed_topic_consumer = User.gen
    @closed_topic_consumer.sig_members.create(:topic => @closed_topic, :role => :consumer)
  end

  it "shouldn't create favourite for guest for public topic" do
    as(Guest.new) do
      response = request("/favourites?topic_id=#{@topic.id}", :method => 'post')
      response.status.should == 401
    end
  end

  it "shouldn't create favourite for guest" do
    as(Guest.new) do
      response = request("/favourites?topic_id=#{@closed_topic.id}", :method => 'post')
      response.status.should == 401
    end
  end

  it "shouldn't create favourite for user who can't have access to the closed topic" do
    as(User.gen) do
      response = request("/favourites?topic_id=#{@closed_topic.id}", :method => 'post')
      response.status.should == 403
    end
  end

  it "should create favourite for registered user for public topic" do
    as(User.gen) do
      lambda do
        response = request("/favourites?topic_id=#{@topic.id}", :method => 'post')
        response.should redirect
      end.should change(Favourite, :count)
    end
  end
  
  it "should create favourite for user who has access for closed topic" do
    [@closed_topic_owner, @closed_topic_maintainer, @closed_topic_consumer].each do |user|
      as(user) do
        lambda do
          response = request("/favourites?topic_id=#{@closed_topic.id}", :method => 'post')
          response.should redirect
        end.should change(Favourite, :count)
      end
    end
  end

  it "should create favourite for user with polish as primary language" do
    user = User.gen(:primary_language => Language["pl"])
    as(user) do
      lambda do
        response = request("/favourites?topic_id=#{@topic.id}", :method => 'post')
        response.should redirect
        response = request(response.headers['Location'])
        response.should have_selector("h2:contains('polska nazwa')")
      end.should change(Favourite, :count)
    end
  end

  it "should create favourite for user with polish as secondary language" do
    user = User.gen(:primary_language => nil)
    user.user_languages.create(:language => Language["pl"])
    as(user) do
      lambda do
        response = request("/favourites?topic_id=#{@topic.id}", :method => 'post')
        response.should redirect
        response = request(response.headers['Location'])
        response.should have_selector("h2:contains('polska nazwa')")
      end.should change(Favourite, :count)
    end
  end

  it "should create favourite for user with polish as browser language" do
    user = User.gen(:primary_language => nil)
    as(user) do
      lambda do
        response = request("/favourites?topic_id=#{@topic.id}", :method => 'post', 'HTTP_ACCEPT_LANGUAGE' => "pl")
        response.should redirect
        response = request(response.headers['Location'])
        response.should have_selector("h2:contains('polska nazwa')")
      end.should change(Favourite, :count)
    end
  end

  it "shouldn't create favourite if user already favourited the topic" do
    user = User.gen
    as(user) do
      lambda do
        response = request("/favourites?topic_id=#{@topic.id}", :method => 'post')
        response.should redirect
      end.should change(Favourite, :count)

      user.reload
      
      lambda do
        response = request("/favourites?topic_id=#{@topic.id}", :method => 'post')
        response.status.should == 400
      end.should_not change(Favourite, :count)
    end
  end

end

describe "Favourite browsing" do

  before(:each) { prepare_fav }

  it "should be successfull" do
    [User.gen, @favourite_owner].each do |user|
      as(user) do
        response = request("/favourites")
        response.should be_successful
      end
    end
  end

end

describe "Favourite viewing" do

  before(:each) { prepare_fav }

  it "should be successful for owner (and should synchronize with topic)" do
    @favourite.topic.topic_elements.create(:element => Element.gen)
    as(@favourite_owner) do
      lambda do
        response = request(resource(@favourite))
        response.should be_successful
      end.should change(FavouriteElement.all_without_scope, :count)
    end
  end

  it "should show 403 for other registered user" do
    as(User.gen) do
      response = request(resource(@favourite))
      response.status.should == 403
    end
  end

  it "should show 401 for guest" do
    as(Guest.new) do
      response = request(resource(@favourite))
      response.status.should == 401
    end
  end

  it "should show list of non-removed elements" do
    fav_elems = @favourite.favourite_elements.all(:limit => 2).to_a
    fav_elems[0].remove!
    removed_elem = fav_elems[0].element
    visible_elem = fav_elems[1].element
    as(@favourite_owner) do
      response = request(resource(@favourite))
      response.should be_successful
      response.should have_selector(".element_list a:contains('#{visible_elem.name[:pl]}')")
      response.should have_selector(".element_list a:contains('#{visible_elem.link.site}')")
      response.should_not have_selector(".element_list a:contains('#{removed_elem.name[:pl]}')")
    end
  end

end

describe "Favourite edit form" do
  it "should have specs"
end

describe "Favourite updating" do
  it "should have specs"
end

describe "Favourite removal" do

  before(:each) { prepare_fav }

  it "should remove favourite for owner" do
    as(@favourite_owner) do
      lambda do
        response = request(resource(@favourite), :method => "delete")
        response.should redirect_to(resource(:favourites))
      end.should change(Favourite, :count).by(-1)
    end
  end

  it "should show 403 for other user" do
    as(User.gen) do
      response = request(resource(@favourite), :method => "delete")
      response.status.should == 403
    end
  end

  it "should show 401 for guest" do
    as(Guest.new) do
      response = request(resource(@favourite), :method => "delete")
      response.status.should == 401
    end
  end
end
