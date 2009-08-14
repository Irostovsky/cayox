class PermalinkForm < OpenStruct

  def valid?
    errors.add(:email, GetText._("You must enter email address")) if self.email.blank?
    errors.add(:email, GetText._("This email address has an invalid format")) unless self.email.to_s =~ DataMapper::Validate::Format::Email::EmailAddress
    errors.add(:lang, GetText._("Language cannot be empty")) if self.lang.blank?
    errors.empty?
  end

  def errors
    @errors ||= DataMapper::Validate::ValidationErrors.new
  end
  
end