require File.join( File.dirname(__FILE__), '..', "spec_helper" )

def create_topic(owner, access_level, tag_list)
  topic = Topic.gen(:access_level => access_level, :tag_list => tag_list)
  topic.sig_members.create(:role => :owner, :user => owner)
  topic
end

def prepare
  TopicElement.all.destroy!
  Element.all.destroy!
  Topic.all.destroy!
  
  @john = User.gen
  create_topic(@john, :public,            "foo")
  create_topic(@john, :closed_user_group, "foo, fiber, bar")
  create_topic(@john, :private,           "foo, fee, fiber, boar, foobar") # prv
  create_topic(@john, :public,            "music")
  create_topic(@john, :closed_user_group, "music, museum, museums")
  create_topic(@john, :private,           "musix") # prv
  create_topic(@john, :public,            "mutex, music, museum")
  create_topic(@john, :closed_user_group, "music, mutex, mutices")
  create_topic(@john, :private,           "mutual") # prv
  create_topic(@john, :public,            "mumin, museum")
  create_topic(@john, :closed_user_group, "mumins, mummy")
  create_topic(@john, :private,           "muthafutha") # prv
  create_topic(@john, :public,            "muthabrutha, hidden").hide! # hidden

  @jane = User.gen
  create_topic(@jane, :public,            "foo, french, fsck, fiber")
  create_topic(@jane, :closed_user_group, "floss, xytras")
  create_topic(@jane, :private,           "foo, french, fsck") # prv

  # for elements tag search
  @public_topic = Topic.gen(:access_level => :public)
  @private_topic = Topic.gen(:access_level => :private)
  @private_topic.sig_members.create(:role => :owner, :user => @john)

  @public_topic.topic_elements.create(:element => Element.gen(:tag_list => "condition, competition, cope, computer, condolences"))
  @public_topic.topic_elements.create(:element => Element.gen(:tag_list => "coke, cope"))
  @public_topic.topic_elements.create(:element => Element.gen(:tag_list => "cope, coke, corky"))
  @public_topic.topic_elements.create(:element => Element.gen(:tag_list => "condition, competition, cope, computer, condolences, cope, coke, corky, foo, bar, removed, codestroyed"), :status => :removed)

  @private_topic.topic_elements.create(:element => Element.gen(:tag_list => "coke, cola")) # prv
  @private_topic.topic_elements.create(:element => Element.gen(:tag_list => "coke, connection")) # prv
  @private_topic.topic_elements.create(:element => Element.gen(:tag_list => "coke, cola, connection, foo, bar, removed, codestroyed"), :status => :removed) # prv + removed
end

describe "Tag search" do

  before(:all) { prepare }

  describe "in topic tags" do

    it "should find tags from public/closed topics" do

      [User.gen, Guest.new, @john, @jane].each do |user|
        # search for all tags
        tags = Tag.search_in_topics([], user)
        %w(foo fiber french fsck floss bar music museum museums mutex mutices mumin mumins mummy xytras).each do |tag_name|
          tags.should include(Tag[tag_name])
        end

        # search for "f"
        tags = Tag.search_in_topics([], user, :like => "f")
        %w(foo fiber french fsck floss).each do |tag_name|
          tags.should include(Tag[tag_name])
        end

        # search for "m"
        tags = Tag.search_in_topics([], user, :like => "m")
        %w(music museum museums mutex mutices mumin mumins mummy).each do |tag_name|
          tags.should include(Tag[tag_name])
        end

        # with context "mutices"
        tags = Tag.search_in_topics([Tag["mutices"]], user)
        tags.size.should == 2
        %w(music mutex).each do |tag_name|
          tags.should include(Tag[tag_name])
        end

        # with context "foo"
        tags = Tag.search_in_topics([Tag["foo"]], user)
        %w(fiber bar french fsck).each do |tag_name|
          tags.should include(Tag[tag_name])
        end

        # with context "museum"
        tags = Tag.search_in_topics([Tag["museum"]], user)
        %w(music museums mutex mumin).each do |tag_name|
          tags.should include(Tag[tag_name])
        end

        # with context "museum, music"
        tags = Tag.search_in_topics([Tag["museum"], Tag["music"]], @john)
        tags.size.should == 2
        %w(museums mutex).each do |tag_name|
          tags.should include(Tag[tag_name])
        end
      end

    end

    it "should find tags from private topics if user is owner" do
      # search for all tags
      tags = Tag.search_in_topics([], @john)
      %w(foo bar music fsck xytras).each do |tag_name| # some public tags
        tags.should include(Tag[tag_name])
      end
      %w(fee boar musix).each do |tag_name| # private tags
        tags.should include(Tag[tag_name])
      end

      # search for "mut"
      tags = Tag.search_in_topics([], @john, :like => "mut")
      tags.should include(Tag["mutual"])
      tags.should include(Tag["muthafutha"])

      # search for "b"
      tags = Tag.search_in_topics([], @john, :like => "b")
      tags.should include(Tag["bar"])
      tags.should include(Tag["boar"])

      # search for "f" (as Jane)
      tags = Tag.search_in_topics([], @jane, :like => "f")
      %w(foo fiber floss french fsck).each do |tag_name|
        tags.should include(Tag[tag_name])
      end

      # with context "fee"
      tags = Tag.search_in_topics([Tag["fee"]], @john)
      %w(foo fiber boar foobar).each do |tag_name|
        tags.should include(Tag[tag_name])
      end
    end

    it "shouldn't find tags from private topics if user isn't owner of topic or is guest" do
      [User.gen, Guest.new, @jane].each do |user|
        # search for "mut"
        tags = Tag.search_in_topics([], user, :like => "mut")
        tags.should include(Tag["mutex"])
        tags.should include(Tag["mutices"])
        tags.should_not include(Tag["mutual"])
        tags.should_not include(Tag["muthafutha"])

        # with context "foo"
        tags = Tag.search_in_topics([Tag["foo"]], user)
        %w(fee boar foobar).each do |tag_name|
          tags.should_not include(Tag[tag_name])
        end
      end
    end

    it "shouldn't find tags from hidden topics" do
      # search for "mut"
      tags = Tag.search_in_topics([], @john, :like => "mut")
      tags.should_not include(Tag["muthabrutha"])

      # with context "foo"
      tags = Tag.search_in_topics([Tag["muthabrutha"]], @john)
      tags.should_not include(Tag["hidden"])
    end

    it "should find tags from owned topics only" do
      tags = Tag.search_in_users_topics([], @jane)
      %w(foo french fsck floss xytras).each do |tag_name|
        tags.should include(Tag[tag_name])
      end
      %w(bar music mutex).each do |tag_name|
        tags.should_not include(Tag[tag_name])
      end

      tags = Tag.search_in_users_topics([], @jane, :like => "f")
      %w(foo fiber french fsck floss).each do |tag_name|
        tags.should include(Tag[tag_name])
      end
      %w(xytras).each do |tag_name|
        tags.should_not include(Tag[tag_name])
      end
    end

    it "should sort found tags by popularity" do
      tags = Tag.search_in_topics([], @john, :like => "f")
      tags.size.should == 7
      tags[0].name.should == "foo"
      tags[1].name.should == "fiber"

      tags = Tag.search_in_topics([], @john, :like => "mu")
      tags.size.should == 11
      tags[0].name.should == "music"
      tags[1].name.should == "museum"
    end

  end

  describe "in topic's element tags" do

   it "should find all tags from elements of topic" do
      Tag.search_in_topic_elements(@public_topic, []).size.should == 7
      Tag.search_in_topic_elements(@private_topic, []).size.should == 3
    end

    it "should find matching tags from elements of topic" do
      Tag.search_in_topic_elements(@public_topic, [], :like => "con").size.should == 2
      Tag.search_in_topic_elements(@private_topic, [], :like => "co").size.should == 3
    end

    it "should find all tags belonging to elements of non-private topics with specified context" do
      public_topic = Topic.gen(:access_level => :public)
      private_topic = Topic.gen(:access_level => :private)
      public_topic.topic_elements.create(:element => Element.gen(:tag_list => "abc, def"))
      public_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo"))
      public_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo, bar"))
      public_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo, bar, baz"))
      public_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo, bar, jolka"))
      public_topic.topic_elements.create(:element => Element.gen(:tag_list => "foo, bar, jolka, misiek"))
      public_topic.topic_elements.create(:element => Element.gen(:tag_list => "abc, hidden")).hide! # should be ignored
      private_topic.topic_elements.create(:element => Element.gen(:tag_list => "abc, foo, bar, ochronislaw")) # should be ignored

      # abc
      tags = Tag.search_in_topic_elements(public_topic, [Tag["abc"]])
      tags.size.should == 1
      tags.should include(Tag["def"])

      # foo
      tags = Tag.search_in_topic_elements(public_topic, [Tag["foo"]])
      tags.size.should == 4
      %w(bar baz jolka misiek).each do |tag_name|
        tags.should include(Tag[tag_name])
      end

      # foo, jolka
      tags = Tag.search_in_topic_elements(public_topic, [Tag["foo"], Tag["jolka"]])
      tags.size.should == 2
      %w(bar misiek).each do |tag_name|
        tags.should include(Tag[tag_name])
      end

    end

    it "should sort found tags by popularity" do
      tags = Tag.search_in_topic_elements(@public_topic, [], :like => "co")
      tags.size.should == 7
      tags[0].name.should == "cope"
      tags[1].name.should == "coke"
    end

  end

  describe "in favourite tags" do

    it "should find tags in given context" do
      owner = User.gen
      Favourite.create_from_topic(Topic.gen(:tag_list => "tag1"), owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "tag1, tag2"), owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "tag1, tag2, tag3"), owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "tag1, tag2, tag3, tag4"), owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "music, metal, death"), owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "music, mentol, bubble"), owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "music, devil, death, rock"), owner)

      Favourite.create_from_topic(Topic.gen(:tag_list => "tag1, tag2, tag3, tag4, music, death, mentol"), User.gen) # this won't be counted

      # only context
      Tag.search_in_favourites([], owner, :limit => 20).size.should == 11
      Tag.search_in_favourites([], owner, :limit => 9).size.should == 9
      Tag.search_in_favourites([Tag["tag1"]], owner, :limit => 10).size.should == 3
      Tag.search_in_favourites([Tag["tag1"], Tag["tag2"]], owner, :limit => 10).size.should == 2
      Tag.search_in_favourites([Tag["tag1"], Tag["tag2"], Tag["tag3"]], owner, :limit => 10).size.should == 1
      Tag.search_in_favourites([Tag["tag1"], Tag["tag2"], Tag["tag3"], Tag["tag4"]], owner, :limit => 10).size.should == 0

      # context with name matching
      Tag.search_in_favourites([Tag["death"]], owner, :like => "m", :limit => 10).size.should == 2
      Tag.search_in_favourites([Tag["music"]], owner, :like => "d", :limit => 10).size.should == 2
      Tag.search_in_favourites([Tag["metal"]], owner, :like => "d", :limit => 10).size.should == 1
    end

  end

  describe "in favourite's element tags" do

    it "should not find tags from removed elements" do
      topic = Topic.gen
      topic.topic_elements.create(:element => Element.gen(:tag_list => "tag1, tag2, tag3"))
      topic.topic_elements.create(:element => Element.gen(:tag_list => "tag3, tag4, tag5"))
      favourite = Favourite.create_from_topic(topic, User.gen)
      Tag.search_in_favourite_elements(favourite, [], :limit => 10).size.should == 5
      favourite.favourite_elements.first.remove!
      Tag.search_in_favourite_elements(favourite, [], :limit => 10).size.should == 3
    end

  end

end

describe "Tag adding/removing" do

  it "should update element_tags" do
    tag = Tag.gen
    element = Element.gen(:tag_list => tag.name)
    lambda do
      element.destroy
    end.should change(ElementTag, :count).by(-1)
  end

  it "should update topic_tags" do
    tag = Tag.gen
    topic = Topic.gen(:tag_list => tag.name)
    lambda do
      topic.destroy
    end.should change(TopicTag, :count).by(-1)
  end

  it "should change tag popularity in topics" do
    tag = Tag.gen
    Topic.gen(:tag_list => tag.name)
    topic = nil
    tag.reload

    lambda do
      topic = Topic.gen(:tag_list => tag.name)
      Topic.gen(:tag_list => tag.name, :access_level => :private) # will not affect
      tag.reload
    end.should change(tag, :non_private_topics_count).by(1)
    
    lambda do
      topic.hide!
      Topic.gen(:tag_list => tag.name, :access_level => :private) # will not affect
      tag.recount_usage_in_topics
    end.should change(tag, :non_private_topics_count).by(-1)

    topic.tag_list = ""
    topic.save
    
    lambda do
      Topic.gen(:tag_list => tag.name, :access_level => :private) # will not affect
      topic.tag_list = tag.name
      topic.save
      tag.reload
    end.should_not change(tag, :non_private_topics_count)
  end

  it "should change tag popularity in elements" do
    tag = Tag.gen
    topic = Topic.gen
    element = Element.gen(:tag_list => tag.name)
    topic_element = nil

    lambda do
      topic.topic_elements.create(:element => Element.gen(:tag_list => tag.name)).hide! # will not affect
      topic_element = topic.topic_elements.create(:element => element)
      tag.reload
    end.should change(tag, :non_private_elements_count).by(1)

    lambda do
      topic_element.hide!
      topic.topic_elements.create(:element => Element.gen(:tag_list => tag.name)).hide! # will not affect
      tag.recount_usage_in_elements
    end.should change(tag, :non_private_elements_count).by(-1)

    element.tag_list = ""
    element.save

    lambda do
      element.tag_list = tag.name
      element.save
      tag.recount_usage_in_elements
    end.should_not change(tag, :non_private_elements_count)
  end

end

describe "Tag cleanup" do

  it "should remove invalid characters and convert to downcase" do
    # testing tag cleanup on topics only as this is implemented in one place for all taggable entities
    topic = Topic.gen(:tag_list => 'Rails 3.0, fOo!, !@#$%^&*()')
    topic.reload
    topic.tags.size.should == 2
    topic.tags.detect { |t| t.name == "rails 3.0" }.should_not be_nil
    topic.tags.detect { |t| t.name == "foo" }.should_not be_nil
  end

end

describe "Tag validation" do

  it "should set error on name field when name longer than 50 chars" do
    tag = Tag.new(:name => "A" * 51)
    tag.should_not be_valid
    tag.errors.on(:name).should_not be_empty
  end

end
