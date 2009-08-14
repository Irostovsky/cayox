class RoleAssignedNotification < RoleNotification

  def subject
    _("Role assigned in Cayox")
  end

  def body
    role = self.data[:role]
    txt = _("You have been assigned a '%s' role for Cayox topic '%s'.") % [_(role.to_s), translate_for_user(Topic.all_without_scope.get(self.data[:topic_id]).name, self.user)]
    has_pending_membership = SigMember.count(:user_id => self.user_id, :topic_id => self.data[:topic_id], :role => role, :accepted => false) > 0
    txt << "\n" << _("Please accept or reject this role on your profile page.") if role == :owner && has_pending_membership
    txt
  end
  
end
