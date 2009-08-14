class SummaryNotification < Notification

  def self.send!(user, notifications)
    new(:user => user, :data => { :notifications => notifications }).send!
  end

  def subject
    _("Summary of notifications from Cayox")
  end

  def body
    self.data[:notifications].select { |n| n.valid? }.map { |n| n.body.to_s.strip }.join("\n\n")
  end

  def after_deliver
    now = DateTime.now
    self.data[:notifications].each do |n|
      n.sent_at = now
      n.save
    end
  end

end