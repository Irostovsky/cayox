class RoleRemovedNotification < RoleNotification

  def subject
    _("Role removed in Cayox")
  end

  def body
    _("Your '%s' role for Cayox topic '%s' has been removed.") % [_(self.data[:role].to_s), translate_for_user(Topic.all_without_scope.get(self.data[:topic_id]).name, self.user)]
  end
  
end
