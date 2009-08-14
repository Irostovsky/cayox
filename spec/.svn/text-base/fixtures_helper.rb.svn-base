def prepare_public_topic
  @topic_owner = User.gen(:primary_language => Language.gen)
  @topic = Topic.gen
  @topic.add_owner(@topic_owner)
  @topic_maintainer = User.gen
  @topic_maintainer.sig_members.create(:topic => @topic, :role => :maintainer)
  @topic_consumer = User.gen
  @topic_consumer.sig_members.create(:topic => @topic, :role => :consumer)

  @element = Element.gen(:name => { :pl => 'old name' })
  @topic_element = @topic.topic_elements.create(:element => @element)
  @topic
end

def prepare_closed_topic
  @closed_topic_owner = User.gen(:primary_language => Language.gen)
  @closed_topic = Topic.gen(:access_level => :closed_user_group)
  @closed_topic.add_owner(@closed_topic_owner)
  @closed_topic_maintainer = User.gen
  @closed_topic_maintainer.sig_members.create(:topic => @closed_topic, :role => :maintainer)
  @closed_topic_consumer = User.gen
  @closed_topic_consumer.sig_members.create(:topic => @closed_topic, :role => :consumer)

  @closed_element = Element.gen(:name => { :pl => 'some name' })
  @closed_topic_element = @closed_topic.topic_elements.create(:element => @closed_element)
  @closed_topic
end

def prepare_private_topic(owner=nil)
  @private_topic_owner = owner || User.gen
  @private_topic = Topic.gen(:access_level => :private)
  @private_topic.add_owner(@private_topic_owner)
  @private_element = Element.gen(:name => { :pl => 'some name' })
  @private_topic_element = @private_topic.topic_elements.create(:element => @private_element)
  @private_topic
end

def prepare_favourite(topic=nil, user=nil)
  topic ||= Topic.gen
  user ||= User.gen
  @favourite_owner = user
  @favourite_imported_element = Element.gen(:name => { :pl => 'Imported One' })
  topic.topic_elements.create(:element => @favourite_imported_element)
  @favourite = Favourite.create_from_topic(topic, @favourite_owner)
  @favourite_custom_element = Element.gen(:name => { :pl => 'Custom One' })
  @favourite.favourite_elements.create(:element => @favourite_custom_element, :custom => true)
  @favourite
end

def propose_element(element)
  @proposition = @favourite.favourite_elements.first(:element_id => element.id).propose!
end
