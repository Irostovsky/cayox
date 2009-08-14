class Notification
  include DataMapper::Resource

  # properties

  property :id,         Serial
  property :type,       Discriminator, :index => true
  property :user_id,    Integer, :nullable => false, :index => true
  property :data,       Yaml, :lazy => false, :default => lambda { Hash.new }
  property :created_at, DateTime, :index => true
  property :sent_at,    DateTime

  # associations

  belongs_to :user

  # pagination

  is :paginated

  # hooks

  before :create do
    throw :halt if self.class == Notification || self.class == SummaryNotification
  end

  after :create do
    self.send!
  end

  # class methods

  def self.type_name
    self.to_s.gsub('Notification', '').snake_case.gsub('_', ' ').capitalize
  end

  def self.types
    (Notification.descendants - [RoleNotification, SummaryNotification]).inject({}) { |acc, n| acc[n.to_s] = n.type_name; acc }
  end
  
  def self.remove_old!(n=Cayox::CONFIG[:max_notification_age])
    Notification.all(:created_at.lt => n.days.ago).destroy!
  end

  def self.remove_invalid!
    Notification.all.reject { |n| n.valid? }.each { |n| n.destroy }
  end

  # instance methods

  def send!
    if self.deliver
      self.after_deliver
    else
      false
    end
  end

  def deliver
    if valid?
      _subject = self.subject
      _body = self.body.strip
      if _body.blank?
        Merb.logger.info "Skipping notification '#{_subject}' to user #{self.user.name} (user_id=#{self.user_id}) because of empty body"
        false
      else
        Merb.logger.info "Sending notification '#{_subject}' to user #{self.user.name} (user_id=#{self.user_id})"
        m = SystemMailer.new(:user => self.user, :body => _body)
        m.dispatch_and_deliver(:system_event, :to => self.user.email, :from => Cayox::CONFIG[:mail_from], :subject => _subject)
      end
    else
      Merb.logger.info "Skipping notification '#{_subject}' to user #{self.user.name} (user_id=#{self.user_id}) because it is not valid anymore"
      false
    end
  end

  def after_deliver
    self.sent_at = DateTime.now
    self.save
  end

  def resource(*args)
    args << {}
    Merb::Router.resource(*args)
  end

  def site_url
    Cayox::CONFIG[:site_url]
  end

  def name
    self.class.type_name
  end

  def subject
    raise RuntimeError, "Implement subject method on your notification model!"
  end

  def body
    raise RuntimeError, "Implement render method on your notification model!"
  end

end
