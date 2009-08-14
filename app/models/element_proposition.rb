class ElementProposition
  include DataMapper::Resource

  # properties

  property :id,                   Serial
  property :topic_id,             Integer, :nullable => false
  property :favourite_element_id, Integer, :nullable => false
  property :status,               Enum[:pending, :accepted, :rejected], :nullable => false, :default => :pending
  property :updated_at,           DateTime # time of acceptance / rejection
  property :created_at,           DateTime
  property :notified_at,          DateTime

  # associations

  belongs_to :topic
  belongs_to :favourite_element

  # behaviour

  is :paginated

  # class methods

  def self.pending
    all(:status => :pending)
  end

  def self.accepted
    all(:status => :accepted)
  end

  def self.rejected
    all(:status => :rejected)
  end
  
  def self.not_notified
    all(:notified_at => nil)
  end

  def self.send_notifications!
    element_propositions = ElementProposition.pending.not_notified

    editors = element_propositions.inject([]) { |acc, ep| acc += ep.topic.editors; acc }.uniq
    editors.each do |user|
      props_ids = element_propositions.select { |ep| ep.topic.in?(user.editable_topics) }.map { |p| p.id }
      ElementPropositionsNotification.create(:user => user, :data => { :propositions_ids => props_ids })
    end

    element_propositions.update!(:notified_at => Time.now)
  end

  # instance methods

  def pending?
    self.status == :pending
  end

  def accepted?
    self.status == :accepted
  end

  def rejected?
    self.status == :rejected
  end

  def accept!
    # change status to accepted
    self.status = :accepted
    self.save
    # create element in topic
    new_element = self.favourite_element.element.clone
    new_element.save
    self.topic.topic_elements.create(:element => new_element)
    # add new topic element to favourite_elements as removed element to prevent importing
    self.favourite_element.favourite.favourite_elements.create(:element => new_element, :custom => false, :status => :removed)
  end

  def reject!
    # change status to rejected
    self.status = :rejected
    self.save
  end
end
