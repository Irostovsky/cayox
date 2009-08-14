require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Flag do

  describe "notifications" do

    before(:all) do
      TopicFlag.all.destroy!
      TopicElementFlag.all.destroy!
    end

    it "should send notifications only to topic owners" do
      topic = Topic.gen
      topic.add_owner(User.gen)
      topic.add_owner(User.gen)
      topic.add_maintainer(User.gen)
      topic.add_consumer(User.gen)
      topic.topic_flags.create(:user => User.gen, :flag => Flag.gen)

      lambda do
        lambda do
          Flag.send_notifications!
        end.should change(TopicFlag.not_notified, :count).by(-1)
      end.should(change(Merb::Mailer.deliveries, :size).by(2))
    end

    it "should include info about topic and elements flagged in one mail message" do
      topic = Topic.gen
      topic.add_owner(User.gen)
      topic.topic_flags.create(:user => User.gen, :flag => Flag.gen)
      3.times do
        topic.topic_elements.create(:element => Element.gen).topic_element_flags.create(:user => User.gen, :flag => Flag.gen(:type => :element))
      end

      lambda do
        lambda do
          lambda do
            Flag.send_notifications!
          end.should change(TopicFlag.not_notified, :count).by(-1)
        end.should change(TopicElementFlag.not_notified, :count).by(-3)
      end.should(change(Merb::Mailer.deliveries, :size).by(1))
    end

    it "should send only one mail per user" do
      owner = User.gen
      topic = Topic.gen
      topic.add_owner(owner)
      topic.add_owner(User.gen)
      topic.topic_flags.create(:user => User.gen, :flag => Flag.gen)
      topic = Topic.gen
      topic.add_owner(owner)
      topic.topic_flags.create(:user => User.gen, :flag => Flag.gen)
      2.times do
        topic.topic_elements.create(:element => Element.gen).topic_element_flags.create(:user => User.gen, :flag => Flag.gen(:type => :element))
      end

      lambda do
        lambda do
          lambda do
            Flag.send_notifications!
          end.should change(TopicFlag.not_notified, :count).by(-2)
        end.should change(TopicElementFlag.not_notified, :count).by(-2)
      end.should(change(Merb::Mailer.deliveries, :size).by(2))
    end
    
    it "shouldn't send notification if they were already sent" do
      topic = Topic.gen
      topic.add_owner(User.gen)
      topic.topic_flags.create(:user => User.gen, :flag => Flag.gen)

      lambda do
        Flag.send_notifications!
      end.should change(Merb::Mailer.deliveries, :size).by(1)

      # this won't send any email
      lambda do
        Flag.send_notifications!
      end.should_not change(Merb::Mailer.deliveries, :size)
    end

    it "shouldn't include info about hidden topics and elements" do
      topic1 = Topic.gen
      topic1.add_owner(User.gen)
      topic1.topic_elements.create(:element => Element.gen).topic_element_flags.create(:user => User.gen, :flag => Flag.gen(:type => :element))
      topic_element = topic1.topic_elements.create(:element => Element.gen)
      topic_element.topic_element_flags.create(:user => User.gen, :flag => Flag.gen(:type => :element))
      topic_element.hide!

      topic2 = Topic.gen
      topic2.add_owner(User.gen)
      topic2.topic_flags.create(:user => User.gen, :flag => Flag.gen)
      topic2.hide!

      lambda do
        lambda do
          lambda do
            Flag.send_notifications!
          end.should_not change(TopicFlag.not_notified, :count)
        end.should change(TopicElementFlag.not_notified, :count).by(-1)
      end.should(change(Merb::Mailer.deliveries, :size).by(1))

    end

  end
  
end