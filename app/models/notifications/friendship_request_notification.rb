class FriendshipRequestNotification < Notification

  validates_with_block :data do
    self.data[:friendship_id] ? true : [false, "You must provide friendship_id in data hash"]
  end

  def subject
    _("Friendship requested in Cayox")
  end

  def body
    inviter = Friendship.get(self.data[:friendship_id]).user
    <<EOF
#{_("User %s wants to become your friend in Cayox.") % inviter.full_name}
#{_("Please accept or reject this friendship on your friends page.")}
EOF
  end
  
end
