class SigMember
  include DataMapper::Resource
  
  # constants
  
  ROLES = [ :consumer, :maintainer, :owner ]
  
  # properties

  property :id,         Serial
  property :role,       Enum[ *ROLES ]
  property :user_id,    Integer, :nullable => false
  property :topic_id,   Integer, :nullable => false
  property :accepted,   Boolean, :default => true
  property :created_at, DateTime
  property :updated_at, DateTime

  # pagination

  is :paginated

  # associations
  
  belongs_to :user
  belongs_to :topic

  # validations

  validates_is_unique :user_id, :scope => :topic_id

  # class methods

  def self.pending
    all(:accepted => false)
  end

  # instance methods

  def accepted?
    self.accepted
  end

  def accept!
    @accepted_by_user = true
    self.accepted = true
    save
  end

  def reject!
    @rejected_by_user = true
    self.destroy
  end
end
