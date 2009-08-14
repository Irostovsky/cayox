class Flag
  include DataMapper::Resource

  # properties

  property :id,          Serial
  property :type,        Enum[:element, :topic], :nullable => false, :index => true
  property :description, Text, :lazy => false, :nullable => false

  # associations

  has n, :topic_flags
  has n, :topic_element_flags

  # class methods

  def self.for_elements
    all(:type => :element, :order => [:id])
  end

  def self.for_topics
    all(:type => :topic, :order => [:id])
  end

  def self.send_notifications!
    all_topic_flags = TopicFlag.pending.not_notified.all(TopicFlag.topic.status => :visible)
    all_topic_element_flags = TopicElementFlag.pending.not_notified.all(TopicElementFlag.topic_element.topic.status => :visible,
                                                                        TopicElementFlag.topic_element.status => :visible)

    owners = (all_topic_flags.inject([]) { |acc, tf| acc += tf.topic.owners; acc } +
              all_topic_element_flags.inject([]) { |acc, tef| acc += tef.topic_element.topic.owners; acc }).uniq

    owners.each do |user|
      topic_flags_ids = all_topic_flags.select { |tf| tf.topic.in?(user.owned_topics) }.map { |tf| tf.id }
      topic_element_flags_ids = all_topic_element_flags.select { |tef| tef.topic_element.topic.in?(user.owned_topics) }.map { |tef| tef.id }
      a = FlagsNotification.create(:user => user, :data => { :topic_flags_ids => topic_flags_ids, :topic_element_flags_ids => topic_element_flags_ids })
      p a.errors unless a.valid?
    end

    now = Time.now
    all_topic_flags.each { |tf| tf.update_attributes(:notified_at => now) }
    all_topic_element_flags.each { |tef| tef.update_attributes(:notified_at => now) }
  end
  
end
