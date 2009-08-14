class TopicElement
  include DataMapper::Resource
  STATUSES = [:visible, :removed, :hidden]
  
  # properties

  property :id,         Serial
  property :votes,      Integer, :nullable => false, :default => 0
  property :ratings,    Integer, :nullable => false, :default => 0
  property :topic_id,   Integer, :nullable => false, :index => true
  property :element_id, Integer, :nullable => false, :index => true
  property :status,     Enum[*STATUSES], :nullable => false, :default => :visible, :index => true
  property :created_at, DateTime
  property :updated_at, DateTime

  # default scope

  default_scope(:default).update(:status => [:visible])

  # associations

  belongs_to :topic
  belongs_to :element
  has n, :topic_element_flags

  # hooks

  after :create,  :recount_element_tags_usage
  after :destroy, :recount_element_tags_usage
  before :destroy do
    self.topic_element_flags.all.destroy!
  end

  # class methods

  def self.all_without_scope
    all(:status => STATUSES)
  end

  def self.removed
    all(:status => :removed)
  end

  def self.with_removed
    all(:status => [:visible, :removed])
  end

  def self.hidden
    all(:status => :hidden)
  end

  def self.status_id(status)
    1 + STATUSES.index(status)
  end

  # instance methods

  def name
    self.element.name
  end

  def visible?
    self.status == :visible
  end

  def private?
    self.topic.private?
  end

  def viewable_by?(user)
    self.element.viewable_by?(user)
  end
  
  def remove!(permanently=false)
    if permanently
      FavouriteElement.all_without_scope.all(:element_id => element.id).destroy!
      self.destroy
      self.element.destroy
    else
      if FavouriteElement.all_without_scope.count(:element_id => element.id) > 0
        self.status = :removed # TODO: why not remove self?
        save
      else
        self.destroy
        self.element.destroy
      end
    end
  end

  def hide!
    if self.visible?
      self.status = :hidden
      save
      FavouriteElement.fresh.all(:element_id => self.element_id).destroy!
    end
  end

  def unhide!
    self.status = :visible
    save
  end

  def permalink(lang_code)
    Cayox::CONFIG[:site_url] + "/topics/#{self.topic_id}/elements/#{self.element_id}-#{self.element.name[lang_code].slug}?lang=#{lang_code}"
  end

  protected

  def recount_element_tags_usage
    self.element.tags.reload.each { |tag| tag.recount_usage_in_elements }
  end
end
