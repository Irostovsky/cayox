require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe TopicElement do

  describe "fetching" do

    before(:each) do
      TopicElement.all.destroy!
      @topic = Topic.gen
      @topic.topic_elements.create(:element => Element.gen, :status => :visible)
      @topic.topic_elements.create(:element => Element.gen, :status => :visible)
      @removed_topic_element = @topic.topic_elements.create(:element => Element.gen, :status => :removed)
      @hidden_topic_element = @topic.topic_elements.create(:element => Element.gen, :status => :hidden)
    end

    it "should fetch only visible topic_elements in TopicElement.all" do
      TopicElement.count.should == 2
      TopicElement.all.size.should == 2
      TopicElement.all.should_not include(@removed_topic_element)
      TopicElement.all.should_not include(@hidden_topic_element)
    end
    
    it "should fetch only visible topic_elements in topic.topic_elements" do
      @topic.topic_elements.count.should == 2
      @topic.topic_elements.reload.all.size.should == 2
      @topic.topic_elements.should_not include(@removed_topic_element)
      @topic.topic_elements.should_not include(@hidden_topic_element)
      @topic.elements.count.should == 2
    end
  end

  describe "removal" do

    before(:each) do
      @topic = Topic.gen
      5.times do
        element = Element.gen
        @topic.topic_elements.create(:element => element)
      end
    end

    it "should mark topic_element as removed if element exists in favourites" do
      Favourite.create_from_topic(@topic, User.gen)
      Favourite.create_from_topic(@topic, User.gen)
      Favourite.create_from_topic(@topic, User.gen)
      Favourite.create_from_topic(Topic.gen, User.gen) # should not cause problems

      topic_element = @topic.topic_elements.first
      lambda do
        lambda do
          lambda do
            lambda do
              lambda do
                lambda do
                  topic_element.remove!
                end.should change(TopicElement, :count).by(-1) # default scope counts only non-removed
              end.should_not change(TopicElement.all_without_scope, :count)
            end.should_not change(FavouriteElement, :count)
          end.should_not change(FavouriteElement.accepted, :count)
        end.should_not change(FavouriteElement.removed_from_topic, :count)
      end.should_not change(Element, :count)
    end

    it "should remove topic_element (with its element) from topic if element doesn't exist in any favourite" do
      topic_element = @topic.topic_elements.first
      lambda do
        lambda do
          lambda do
            topic_element.remove!
          end.should change(TopicElement.all_without_scope, :count).by(-1)
        end.should change(Element, :count).by(-1)
      end.should_not change(FavouriteElement, :count)
    end
  end

  describe "hiding" do

    it "should hide element (but not remove the record)" do
      topic = Topic.gen
      3.times { topic.topic_elements.create(:element => Element.gen) }
      lambda do
        lambda do
          lambda do
            topic.topic_elements.first.hide!
          end.should change(TopicElement, :count).by(-1)
        end.should change(topic.topic_elements, :count).by(-1)
      end.should_not change(TopicElement.all(:status => TopicElement::STATUSES), :count)
    end

    it "should remove all fresh favourite_elements related to this element" do
      topic = Topic.gen
      favourite = Favourite.create_from_topic(topic, User.gen)
      topic_element = topic.topic_elements.create(:element => Element.gen)
      favourite.synchronize
      lambda do
        lambda do
          topic_element.hide!
        end.should change(FavouriteElement.fresh, :count).by(-1)
      end.should change(FavouriteElement.all_without_scope, :count).by(-1)
    end

  end

end
