require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe ElementProposition do

  describe "request" do

    before(:all) do
      prepare_public_topic
      favourite = Favourite.create_from_topic(@topic, User.gen)
      favourite_element = favourite.favourite_elements.create(:element => Element.gen, :custom => true, :status => :accepted)
      @element_proposition = favourite_element.propose!
    end

    it "should be accepted" do
      lambda do
        lambda do
          lambda do
            lambda do
              lambda do
                @element_proposition.accept!
                @topic.reload
              end.should change(ElementProposition.pending, :count).by(-1)
            end.should change(ElementProposition.accepted, :count).by(1)
          end.should change(@topic.topic_elements, :count).by(1)
        end.should change(Element, :count).by(1)
      end.should change(FavouriteElement.removed, :count).by(1)
    end

    it "should be rejected" do
      lambda do
        lambda do
          @element_proposition.reject!
        end.should change(ElementProposition.pending, :count).by(-1)
      end.should change(ElementProposition.rejected, :count).by(1)
    end

  end

  describe "notifications" do

    before(:all) { ElementProposition.all.destroy! }

    it "should send notifications to topic owners and maintainers" do
      topic = Topic.gen
      topic.add_owner(User.gen)
      topic.add_maintainer(User.gen)
      topic.add_consumer(User.gen)
      favourite = Favourite.create_from_topic(topic, User.gen)
      favourite.add_custom_element(Element.gen).propose!

      lambda do
        lambda do
          ElementProposition.send_notifications!
        end.should change(ElementProposition.not_notified, :count).by(-1)
      end.should(change(Merb::Mailer.deliveries, :size).by(2))
    end

    it "should send only one mail per user" do
      topic_owner = User.gen
      topic = Topic.gen
      topic.add_owner(topic_owner)
      topic2 = Topic.gen
      topic2.add_owner(User.gen)
      topic.add_maintainer(User.gen)
      topic.add_consumer(User.gen)
      topic2.add_maintainer(topic_owner)
      favourite1 = Favourite.create_from_topic(topic, User.gen)
      favourite2 = Favourite.create_from_topic(topic, User.gen)
      favourite3 = Favourite.create_from_topic(topic2, User.gen)
      favourite1.add_custom_element(Element.gen).propose!
      favourite1.add_custom_element(Element.gen).propose!
      favourite2.add_custom_element(Element.gen).propose!
      favourite3.add_custom_element(Element.gen).propose!
      favourite3.add_custom_element(Element.gen).propose!
      favourite3.add_custom_element(Element.gen).propose!

      lambda do
        lambda do
          ElementProposition.send_notifications!
        end.should change(ElementProposition.not_notified, :count).by(-6)
      end.should change(Merb::Mailer.deliveries, :size).by(3)
    end
    
    it "shouldn't send notification if they were already sent" do
      topic = Topic.gen
      topic.add_owner(User.gen)
      favourite = Favourite.create_from_topic(topic, User.gen)
      favourite.add_custom_element(Element.gen).propose!

      lambda do
        lambda do
          ElementProposition.send_notifications!
        end.should change(ElementProposition.not_notified, :count).by(-1)
      end.should change(Merb::Mailer.deliveries, :size).by(1)

      # this won't send any email
      lambda do
        lambda do
          ElementProposition.send_notifications!
        end.should_not change(ElementProposition.not_notified, :count)
      end.should_not change(Merb::Mailer.deliveries, :size)
    end

  end
  
end