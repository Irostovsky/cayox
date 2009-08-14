class RegistrationNotification < Notification

  def subject
    _("Welcome to Cayox!")
  end

  def body
    pass = self.user.password ? "\n  #{_("password")}: #{self.user.password}" : ""
    <<EOF
#{_("Your account has been created with following credentials:")}

  #{_("full name")}: #{self.user.full_name}
  #{_("screen name")}: #{self.user.name}#{pass}

#{_("In order to use your account you must activate it by clicking on following link:")}

  #{site_url + resource(:users, :activate, :token => self.user.activation_token)}
EOF
  end

end