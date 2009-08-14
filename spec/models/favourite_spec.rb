require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Favourite do

  describe "elements" do

    it "should not include removed and hidden elements" do
      topic = Topic.gen
      topic.topic_elements.create(:element => Element.gen)
      topic.topic_elements.create(:element => Element.gen)
      topic.topic_elements.create(:element => Element.gen)
      favourite = Favourite.create_from_topic(topic, User.gen)
      lambda do
        fav_elems = favourite.favourite_elements.all(:limit => 2)
        fav_elems[0].remove!
        fav_elems[1].hide!
      end.should change(favourite.favourite_elements, :count).by(-2)
    end

  end

  describe "creation" do

    it "should be created with name and desc in user's language" do
      topic = Topic.gen(:name => { "pl" => "polska nazwa", "en" => "english name" }, :description => { "pl" => "polski opis", "en" => "english desc" })

      favourite = Favourite.create_from_topic(topic, User.gen(:primary_language => Language["pl"]))
      favourite.name.should == "polska nazwa"
      favourite.description.should == "polski opis"

      favourite = Favourite.create_from_topic(topic, User.gen(:primary_language => Language["en"]))
      favourite.name.should == "english name"
      favourite.description.should == "english desc"
    end

    it "should be created with tags from topic" do
      topic = Topic.gen(:tag_list => "tag1, tag2, tag3")
      favourite = Favourite.create_from_topic(topic, User.gen)
      favourite = Favourite.get(favourite.id)
      favourite.tags.count.should == 3
      favourite.tags.should include(Tag["tag1"])
      favourite.tags.should include(Tag["tag2"])
      favourite.tags.should include(Tag["tag3"])
    end

    it "should be created with elements from topic" do
      topic = Topic.gen
      element1 = Element.gen
      element2 = Element.gen(:tag_list => "foo, bar")
      element3 = Element.gen(:tag_list => "foo, jola, misio")
      element4 = Element.gen(:tag_list => "foo, jola, misio, removed")
      element5 = Element.gen(:tag_list => "foo, jola, misio, hidden")
      topic.topic_elements.create(:element => element1)
      topic.topic_elements.create(:element => element2)
      topic.topic_elements.create(:element => element3)
      topic.topic_elements.create(:element => element4, :status => :removed)
      topic.topic_elements.create(:element => element5, :status => :hidden)

      favourite = Favourite.create_from_topic(topic, User.gen)
      favourite = Favourite.get(favourite.id)
      favourite.elements.count.should == 3
      favourite.elements.should include(element1)
      favourite.elements.should include(element2)
      favourite.elements.should include(element3)
      favourite.favourite_elements.all? { |fe| !fe.custom }.should be_true
    end

    it "should be created with empty sunchronized_at property" do
      topic = Topic.gen
      favourite = Favourite.create_from_topic(topic, User.gen)
      Favourite.get(favourite.id).synchronized_at.should be_nil
    end

  end

  describe "search" do

    before(:all) do
      @owner = User.gen
      Favourite.create_from_topic(Topic.gen(:tag_list => "foo"), @owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "foo, bar"), @owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "foo, bar, baz"), @owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "foo, bar, baz, misio"), @owner)
      Favourite.create_from_topic(Topic.gen(:tag_list => "bar, misio"), @owner)
    end

    it "should return page count and fav list" do
      per_page = 3
      page_count, favourites = Favourite.search([], :user => @owner, :per_page => per_page, :page => 1)
      page_count.should == 2
      favourites.size.should == per_page
    end

    it "should return filtered fav list when context given" do
      _, favourites = Favourite.search([Tag["foo"]], :user => @owner, :per_page => 10, :page => 1)
      favourites.size.should == 4

      _, favourites = Favourite.search([Tag["foo"], Tag["bar"]], :user => @owner, :per_page => 10, :page => 1)
      favourites.size.should == 3

      _, favourites = Favourite.search([Tag["foo"], Tag["bar"], Tag["baz"]], :user => @owner, :per_page => 10, :page => 1)
      favourites.size.should == 2
    end

  end

  describe "removal" do

    it "should remove FavouriteElement records and custom Elements" do
      owner = User.gen

      some_topic = Topic.gen(:tag_list => "bar")
      some_topic.topic_elements.create(:element => Element.gen)
      some_topic.topic_elements.create(:element => Element.gen)
      some_topic.topic_elements.create(:element => Element.gen)
      some_favourite = Favourite.create_from_topic(some_topic, owner)
      some_favourite.favourite_elements.create(:element => Element.gen, :custom => true)

      topic = Topic.gen(:tag_list => "foo")
      topic.topic_elements.create(:element => Element.gen)
      topic.topic_elements.create(:element => Element.gen)
      favourite = Favourite.create_from_topic(topic, owner)
      favourite.favourite_elements.create(:element => Element.gen, :custom => true)
      
      lambda do
        lambda do
          lambda do
            favourite.destroy
          end.should change(Favourite, :count).by(-1)
        end.should change(FavouriteElement, :count).by(-3)
      end.should change(Element, :count).by(-1)
    end

    it "should remove taggings upon removal" do
      fav = Favourite.create_from_topic(Topic.gen(:tag_list => "tag1, tag2, tag3"), User.gen)
      lambda do
        fav.destroy
      end.should change(FavouriteTag, :count).by(-3)
    end

  end

  describe "synchronization" do

    before(:all) do
      @topic_owner = User.gen
      @topic = Topic.gen(:access_level => :closed_user_group)
      @topic.add_owner(@topic_owner)
      5.times { @topic.topic_elements.create(:element => Element.gen) }
      @topic.topic_elements.create(:element => Element.gen, :status => :removed)
      @topic.topic_elements.create(:element => Element.gen, :status => :hidden)
      @favourite_owner = User.gen
      @topic.add_consumer(@favourite_owner) # he is consumer of @topic
      @favourite = Favourite.create_from_topic(@topic, @favourite_owner) # so he can create favourite from it
      @favourite.add_custom_element(Element.gen)
    end

    before(:each) do
      @topic.reload
      @favourite.reload
    end

    it "should have all initial elements with status accepted" do
      @favourite.favourite_elements.all? { |fe| fe.status == :accepted }.should be_true
      @favourite.favourite_elements.count.should == 5 + 1 # not counting removed and hidden from topic, counting 1 custom element
    end

    it "should not add elements if topic didn't change" do
      lambda do
        lambda do
          lambda do
            lambda do
              @favourite.synchronize
            end.should_not change(FavouriteElement.fresh, :count)
          end.should_not change(FavouriteElement.removed, :count)
        end.should_not change(FavouriteElement.removed_from_topic, :count)
      end.should_not change(FavouriteElement.accepted, :count)
    end

    it "should add all new elements (without hidden and removed) with status :fresh" do
      @topic.topic_elements.create(:element => Element.gen)
      @topic.topic_elements.create(:element => Element.gen)
      @topic.topic_elements.create(:element => Element.gen, :status => :removed)
      @topic.topic_elements.create(:element => Element.gen, :status => :hidden)
      lambda do
        @favourite.synchronize
      end.should change(FavouriteElement.fresh, :count).by(2)
    end

    it "should mark favourite_elements with status :removed_from_topic and remove original topic_element + element (if no one else uses this element in his favourite)" do
      @topic.topic_elements.reload.all(:limit => 2).each { |te| te.remove! }
      lambda do
        lambda do
          lambda do
            lambda do
              @favourite.synchronize
            end.should change(FavouriteElement.accepted, :count).by(-2)
          end.should change(FavouriteElement.removed_from_topic, :count).by(2)
        end.should change(TopicElement.with_removed, :count).by(-2)
      end.should_not change(Element, :count) # -2 (from topic_element) + 2 (to fav_elem)
    end

    it "should mark elements with status :removed_from_topic and NOT remove original topic_element + element (if other user has this element in his favourite)" do
      user = User.gen
      @topic.add_consumer(user)
      some_favourite = Favourite.create_from_topic(@topic, user)
      @topic.topic_elements.reload.all(:limit => 2).each { |te| te.remove! }

      lambda do
        lambda do
          lambda do
            lambda do
              @favourite.synchronize
            end.should change(FavouriteElement.accepted, :count).by(-2)
          end.should change(FavouriteElement.removed_from_topic, :count).by(2)
        end.should_not change(TopicElement, :count)
      end.should change(Element, :count).by(2) # (in fav_elem)

      lambda do
        lambda do
          lambda do
            lambda do
              some_favourite.synchronize
            end.should change(FavouriteElement.accepted, :count).by(-2)
          end.should change(FavouriteElement.removed_from_topic, :count).by(2)
        end.should change(TopicElement.with_removed, :count).by(-2)
      end.should_not change(Element, :count) # -2 (from topic_element) + 2 (to fav_elem)
    end

    it "should hide favourite element if respective topic element has been hidden" do
      @topic.topic_elements.first.hide!
      lambda do
        lambda do
          lambda do
            @favourite.synchronize
          end.should change(FavouriteElement.accepted, :count).by(-1)
        end.should change(FavouriteElement.hidden, :count).by(1)
      end.should change(@favourite.favourite_elements, :count).by(-1)
    end

    it "should remove favourite_elements+element+topic_element if element was removed from all favs and then from topic" do
      # create another favourite from @topic
      user = User.gen
      second_favourite = Favourite.create_from_topic(@topic, user)
      @topic.add_consumer(user)
      # remove from all favourites
      fav_elem = @favourite.favourite_elements.first(:custom => false)
      fav_elem.remove!
      element = fav_elem.element
      second_favourite.favourite_elements.first(:element_id => element.id).remove!

      # remove from topic
      lambda do
        lambda do
          te = @topic.topic_elements.first(:element_id => element.id)
          te.remove!
        end.should change(TopicElement, :count).by(-1)
      end.should_not change(TopicElement.all_without_scope, :count)

      # synchronize @favourite
      lambda do
        lambda do
          lambda do
            @favourite.synchronize
          end.should_not change(Element, :count)
        end.should_not change(TopicElement.all_without_scope, :count)
      end.should change(FavouriteElement.all_without_scope, :count).by(-1)

      # synchronize second_favourite
      lambda do
        lambda do
          lambda do
            second_favourite.synchronize
          end.should change(FavouriteElement.all_without_scope, :count).by(-1)
        end.should change(Element, :count).by(-1)
      end.should change(TopicElement.all_without_scope, :count).by(-1)
    end

    it "should not add elements if they were previously removed from favourite" do
      # remove from favourite
      @favourite.favourite_elements.first(:custom => false).remove!
      lambda do
        lambda do
          lambda do
            @favourite.synchronize
          end.should_not change(FavouriteElement, :count)
        end.should_not change(FavouriteElement.removed, :count)
      end.should_not change(FavouriteElement.fresh, :count)
    end

    it "should not be performed if user lost access to topic" do
      some_favourite = Favourite.create_from_topic(@topic, User.gen) # this user has no sig_members records, can't see the topic

      # modify topic
      @topic.topic_elements.first.remove!
      @topic.topic_elements.create(:element => Element.gen)
      @topic.topic_elements.create(:element => Element.gen)

      @topic.sig_members.all(:user_id => @favourite_owner.id).destroy! # remove access to @topic for @favourite_owner
      [@favourite, some_favourite].each do |fav|
        lambda do
          lambda do
            lambda do
              lambda do
                fav.synchronize
              end.should_not change(FavouriteElement.fresh, :count)
            end.should_not change(FavouriteElement.removed, :count)
          end.should_not change(FavouriteElement.removed_from_topic, :count)
        end.should_not change(FavouriteElement.accepted, :count)
      end
    end

    it "should not be performed if topic has been hidden" do
      @favourite.topic.topic_elements.create(:element => Element.gen)
      @favourite.topic.hide!
      @favourite.reload
      lambda do
        lambda do
          @favourite.synchronize
        end.should_not change(FavouriteElement.fresh, :count)
      end.should_not change(@favourite, :synchronized_at)
    end

    it "should update synchronized_at property" do
      lambda do
        @favourite.synchronize
      end.should change(@favourite, :synchronized_at)
    end

    it "should be performed if it was performed more than Favourite::SYNC_INTERVAL minutes ago" do
      @favourite.synchronized_at = Favourite::SYNC_INTERVAL.minutes.ago - 10.seconds
      @favourite.save
      @topic.topic_elements.create(:element => Element.gen)
      lambda do
        @favourite.synchronize
      end.should change(FavouriteElement.fresh, :count)
    end
    
    it "should not be performed if it was performed less than Favourite::SYNC_INTERVAL minutes ago" do
      @favourite.synchronized_at = Favourite::SYNC_INTERVAL.minutes.ago + 20.seconds
      @favourite.save
      @topic.topic_elements.create(:element => Element.gen)
      lambda do
        lambda do
          @favourite.synchronize
        end.should_not change(FavouriteElement.fresh, :count)
      end.should_not change(@favourite, :synchronized_at)
    end

    it "should be performed if it was performed less than Favourite::SYNC_INTERVAL minutes ago but is forced" do
      @favourite.synchronized_at = Favourite::SYNC_INTERVAL.minutes.ago + 20.seconds
      @favourite.save
      @topic.topic_elements.create(:element => Element.gen)
      lambda do
        @favourite.synchronize(true)
      end.should change(FavouriteElement.fresh, :count)
    end
  end

end