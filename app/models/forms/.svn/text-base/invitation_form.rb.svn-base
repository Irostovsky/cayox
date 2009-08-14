class InvitationForm < OpenStruct

  def valid_for?(user)
    errors.add(:email, GetText._("You must enter email address")) if self.email.blank?
    errors.add(:email, GetText._("This email address has an invalid format")) unless self.email.to_s =~ DataMapper::Validate::Format::Email::EmailAddress

    if user.email == self.email
      errors.add(:email, GetText._("Sorry, but you can't invite yourself."))
    elsif friend = User.first(:email => self.email)
      if friendship = Friendship.first(:user_id => user.id, :friend_id => friend.id)
        if friendship.accepted?
          errors.add(:email, GetText._("Friendship already exists."))
        else
          errors.add(:email, GetText._("User with this email has already been invited."))
        end
      end
    end

    errors.empty?
  end

  def errors
    @errors ||= DataMapper::Validate::ValidationErrors.new
  end
  
end
