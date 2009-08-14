class TopicElementFlag
  include DataMapper::Resource

  # properties

  property :id,               Serial
  property :topic_element_id, Integer, :nullable => false, :index => true
  property :flag_id,          Integer, :nullable => false, :index => true
  property :user_id,          Integer, :nullable => true, :index => true
  property :status,           Enum[:pending, :accepted, :rejected], :nullable => false, :default => :pending, :index => true
  property :created_at,       DateTime
  property :updated_at,       DateTime
  property :notified_at,      DateTime

  # validations

  validates_is_unique :user_id, :scope => :topic_element_id, :if => proc { |r| !r.user_id.nil? }

  is :paginated

  # associations

  belongs_to :topic_element
  belongs_to :flag
  belongs_to :user

  # class methods

  def self.pending
    all(:status => :pending)
  end

  def self.not_notified
    all(:notified_at => nil)
  end

  def self.visible
    all(TopicElementFlag.topic_element.topic.status => :visible, TopicElementFlag.topic_element.status => :visible)
  end

  # instance methods

  def accept!
    self.status = :accepted
    save
    self.topic_element.hide!
  end

  def reject!
    self.status = :rejected
    save
  end

  def pending?
    self.status == :pending
  end

  def rejected?
    self.status == :rejected
  end

  def name
    self.topic_element.element.name
  end

  def description
    self.topic_element.element.description
  end
end
