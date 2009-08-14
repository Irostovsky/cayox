require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe FavouriteElement do

  describe "creation" do

    it "should not add element to favourite which already contains this element" do
      topic = Topic.gen
      element = Element.gen

      lambda do
        topic.topic_elements.create(:element => element)
      end.should change(TopicElement, :count).by(1)

      favourite = Favourite.create_from_topic(topic, User.gen)

      lambda do
        favourite.favourite_elements.create(:element => element, :custom => false)
      end.should_not change(FavouriteElement, :count)

      lambda do
        favourite.add_custom_element(element)
      end.should_not change(FavouriteElement, :count)
    end

  end

  describe "removal" do

    before(:all) do
      topic = Topic.gen
      5.times { topic.topic_elements.create(:element => Element.gen) }
      @favourite = Favourite.create_from_topic(topic, User.gen)
      @favourite.add_custom_element(Element.gen)
    end

    it "should mark favourite_element as removed if imported" do
      fav_elem = @favourite.favourite_elements.first(:custom => false)
      lambda do
        lambda do
          lambda do
            lambda do
              fav_elem.remove!
            end.should_not change(Element, :count)
          end.should change(FavouriteElement, :count).by(-1)
        end.should change(FavouriteElement.removed, :count).by(1)
      end.should change(FavouriteElement.accepted, :count).by(-1)
    end

    it "should remove favourite_element (with its element) from favourite if custom" do
      fav_elem = @favourite.favourite_elements.custom.first
      lambda do
        lambda do
          fav_elem.remove!
        end.should change(FavouriteElement, :count).by(-1)
      end.should change(Element, :count).by(-1)
    end

    it "should remove associated element propositions" do
      fav_elem = @favourite.favourite_elements.custom.first
      fav_elem.propose!
      lambda do
        fav_elem.remove!
      end.should change(ElementProposition, :count).by(-1)
    end

  end

  describe "proposing" do

    it "should add element to topic's proposed elements list" do
      topic = Topic.gen
      favourite = Favourite.create_from_topic(topic, User.gen)
      element = Element.gen
      fav_elem = favourite.add_custom_element(element)
      lambda do
        fav_elem.propose!
      end.should change(ElementProposition, :count)
      
      topic.element_propositions.map { |ep| ep.favourite_element.element }.should include(element)
    end
    
    it "shouldn't add element to topic's proposed elements list if element is not custom" do
      topic = Topic.gen
      topic.topic_elements.create(:element => Element.gen)
      favourite = Favourite.create_from_topic(topic, User.gen)
      fav_elem = favourite.favourite_elements.first
      lambda do
        fav_elem.propose!
      end.should_not change(ElementProposition, :count)
    end
  end

end