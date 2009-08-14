class ElementPropositionsNotification < Notification

  validates_with_block :data do
    self.data[:propositions_ids] ? true : [false, "You must provide propositions_ids in data hash"]
  end

  def subject
    _("New Cayox elements proposed")
  end

  def body
    propositions = ElementProposition.all(:id => self.data[:propositions_ids])
    return nil if propositions.empty?
    txt = _("Cayox users proposed following elements to include in your topics:") << "\n\n"
    propositions.each do |p|
      element = p.favourite_element.element
      txt << "  " << translate_for_user(element.name, self.user) << " - " << element.url << " (" << _("for topic '%s'") % translate_for_user(p.topic.name, self.user) << ")\n"
    end
    txt << "\n" << _("You can accept or reject proposed elements at ") << site_url + resource(:element_propositions)
  end
  
end
