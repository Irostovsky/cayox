class FavouriteElement
  include DataMapper::Resource
  STATUSES = [:accepted, :fresh, :removed, :removed_from_topic, :hidden]

  # properties

  property :id,         Serial
  property :position,   Integer
  property :created_at, DateTime
  property :updated_at, DateTime
  property :custom,     Boolean, :nullable => false
  property :status,     Enum[*STATUSES], :nullable => false, :default => :accepted # status 1 and 4 - visible in listing and search

  # associations

  belongs_to :favourite
  belongs_to :element

  has n, :element_propositions

  # validations

  validates_is_unique :element_id, :scope => :favourite_id

  # default scope

  default_scope(:default).update(:status => [:accepted, :removed_from_topic])

  # hooks

  before :destroy do
    self.element_propositions.destroy!
  end

  # class methods

  def self.all_without_scope
    all(:status => STATUSES)
  end

  def self.custom
    all(:custom => true)
  end

  def self.fresh
    all(:status => :fresh)
  end

  def self.accepted
    all(:status => :accepted)
  end

  def self.removed_from_topic
    all(:status => :removed_from_topic)
  end

  def self.removed
    all(:status => :removed)
  end

  def self.hidden
    all(:status => :hidden)
  end

  def self.status_id(status)
    1 + STATUSES.index(status)
  end

  # instance methods

  def custom?
    self.custom
  end

  def removed?
    self.status == :removed
  end
  
  def accept!
    self.status = :accepted
    save
  end

  def remove!
    if self.custom?
      self.destroy
      self.element.destroy
    else
      self.status = :removed
      save
    end
  end

  def hide!
    unless self.status == :removed
      self.status = :hidden
      save
    end
  end

  def proposition
    @proposition ||= self.favourite.topic && self.favourite.topic.element_propositions.first(:favourite_element_id  => self.id)
  end

  def propose!
    return nil unless self.custom? && self.favourite.topic
    self.favourite.topic.element_propositions.create(:topic_id => self.favourite.topic_id, :favourite_element_id => self.id)
  end

end
