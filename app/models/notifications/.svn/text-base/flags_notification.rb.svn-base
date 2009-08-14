class FlagsNotification < Notification

  validates_with_block :data do
    if self.data[:topic_flags_ids].nil?
      [false, "You must provide topic_flags_ids in data hash"]
    elsif self.data[:topic_element_flags_ids].nil?
      [false, "You must provide topic_element_flags_ids in data hash"]
    else
      true
    end
  end

  def self.type_name
    "New flagged items"
  end
  
  def subject
    _("Flagged Cayox topics and elements")
  end

  def body
    topic_flags = TopicFlag.pending.visible.all(:id => self.data[:topic_flags_ids])
    topic_element_flags = TopicElementFlag.pending.visible.all(:id => self.data[:topic_element_flags_ids])
    return nil if topic_flags.size + topic_element_flags.size == 0
    txt = ""
    unless topic_flags.empty?
      txt << _("Following of your topics have been flagged:") << "\n\n"
      topic_flags.each do |tf|
        txt << "  '" << translate_for_user(tf.topic.name, self.user) << "' " << _("as") << " " << _(tf.flag.description) << "\n"
      end
      txt << "\n"
    end
    unless topic_element_flags.empty?
      txt << _("Following of your elements have been flagged:") << "\n\n"
      topic_element_flags.each do |tef|
        txt << "  '" << translate_for_user(tef.topic_element.element.name, self.user) << "' (" << _("in topic '%s'") % translate_for_user(tef.topic_element.topic.name, self.user) << ") " << _("as") << " " << _(tef.flag.description) << "\n"
      end
      txt << "\n"
    end
    txt << "\n" << _("You can manage flagged items at") << " " << site_url + resource(:flags)
    txt
  end

end
