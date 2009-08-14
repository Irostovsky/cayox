class MembershipRequestsNotification < Notification

  validates_with_block :data do
    self.data[:membership_requests_ids] ? true : [false, "You must provide membership_requests_ids in data hash"]
  end

  def subject
    _("New pending membership request for your closed topic")
  end

  def body
    requests = MembershipRequest.all(:id => self.data[:membership_requests_ids])
    return nil if requests.empty?
    topics_and_memberships = requests.group_by { |r| r.topic }
    txt = ""
    topics_and_memberships.each do |topic, memberships|
      txt << _("Following users want to join topic '%s':") % translate_for_user(topic.name, self.user)
      memberships.each do |m|
        txt << "  " << m.user.name << "\n"
      end
      txt << _("To accept or reject these requests go to: ") << site_url + resource(topic, :sig_members)
      txt << "\n"
    end
    txt
  end

end
