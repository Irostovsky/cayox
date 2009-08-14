class InvitationNotification < Notification

  def subject
    _("Invited to Cayox!")
  end

  def body
    <<EOF
#{_("%s invites you to Cayox.") % self.user.inviter.full_name}

#{_("In order to use your account you must activate it by clicking on following link:")}

  #{site_url + resource(:users, :activate, :token => self.user.activation_token)}
EOF
  end
  
end
