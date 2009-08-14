class RoleNotification < Notification

  validates_with_block :data do
    if self.data[:role].blank?
      [false, "You must provide role in data hash"]
    elsif self.data[:topic_id].blank?
      [false, "You must provide topic_id in data hash"]
    elsif Topic.get(self.data[:topic_id]).nil?
      [false, "Topic with id=#{self.data[:topic_id]} is hidden or removed"]
    else
      true
    end
  end

  def subject
    _("Role changed in Cayox")
  end

  def body
    role = self.data[:role]
    txt = _("Your role for Cayox topic '%s' has been changed to '%s'.") % [translate_for_user(Topic.all_without_scope.get(self.data[:topic_id]).name, self.user), _(role.to_s)]
    txt << "\n" << _("Please accept or reject this role on your profile page.") if role == :owner
    txt
  end
  
end
