class PasswordResetNotification < Notification

  def subject
    _("Password reset link from Cayox")
  end

  def body
    <<EOF
#{_("As you need to reset password for your account please click on following link to setup new password:")}

  #{site_url + resource(:users, :reset_password, :token => self.user.password_reset_token)}
EOF
  end
  
end
