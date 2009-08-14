class NotificationsFilterForm < OpenStruct

  def valid?
    begin
      self.date_from = self.date_from.blank? ? nil : Date.parse(self.date_from)
    rescue
      errors.add(:date_from, GetText._("Date from has invalid format"))
    end
    begin
      self.date_to = self.date_to.blank? ? nil : Date.parse(self.date_to)
    rescue
      errors.add(:date_to, GetText._("Date to has invalid format"))
    end
    errors.empty?
  end

  def errors
    @errors ||= DataMapper::Validate::ValidationErrors.new
  end
  
end
