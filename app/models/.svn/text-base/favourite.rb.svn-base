require Merb.root / "app" / "models" / "favourite_element.rb"

class Favourite
  include DataMapper::Resource
  
  SYNC_INTERVAL = ::Cayox::CONFIG[:favourite_sync_interval]

  # properties

  property :id,               Serial
  property :name,             String, :nullable => false, :length => 100
  property :description,      Text, :lazy => false
  property :created_at,       DateTime
  property :updated_at,       DateTime
  property :synchronized_at,  DateTime

  # validations

  validates_present :name, :message => GetText._("Name must no be blank")
  validates_length :name, :max => 100, :message => GetText._("Name must be less than 100 characters long")
  validates_length :description, :max => 1024, :message => GetText._("Description must be less than 1024 characters long")

  validates_with_block :tag_list do
    if self.tag_list.join(",").size > 1024
      [false, GetText._("Tag list must be less than 1024 characters long")]
    else
      true
    end
  end

  # associations

  belongs_to :user
  belongs_to :topic
  has n, :favourite_elements
  has n, :elements, :through => :favourite_elements, FavouriteElement.properties[:status] => [:accepted, :removed_from_topic]
  has n, :new_elements, :through => :favourite_elements, FavouriteElement.properties[:status] => :fresh, :class_name => "Element", :child_key => [:favourite_id], :remote_relationship_name => :element

  is :paginated

  # hooks

  before :destroy, :remove_associated_objects
  
  # class methods

  def self.create_from_topic(topic, user, default_language=nil)
    favourite = Favourite.create(:name => translate_for_user(topic.name, user, default_language),
                                 :description => translate_for_user(topic.description, user, default_language),
                                 :tag_list => topic.tag_list.join(","),
                                 :topic => topic,
                                 :user => user)
    topic.elements.each { |e| favourite.favourite_elements.create(:element => e, :custom => false) }
    favourite
  end

  def self.search_query(tag_ids, opts)
    user = opts[:user] or raise ArgumentError, GetText._("You need to specify user for favourite search!")
    tag_clause = nil
    having_clause = nil
    favourite_tags_join = nil

    unless tag_ids.empty?
      favourite_tags_join = "INNER JOIN favourite_tags ft ON (f.id = ft.favourite_id)"
      tag_clause = "AND ft.tag_id IN (#{tag_ids.join(',')})"
      having_clause = "HAVING COUNT(*) = #{tag_ids.size}"
    end

    "FROM favourites f #{favourite_tags_join} WHERE f.user_id = #{user.id} #{tag_clause} \
     GROUP BY f.id, f.name, f.description, f.created_at, f.updated_at, f.synchronized_at #{having_clause}"
  end

  def self.search(tags, opts)
    per_page = opts[:per_page] or raise ArgumentError, GetText._("You need to specify per_page parameter!")
    page = opts[:page]-1
    limit_clause =  "LIMIT #{per_page} OFFSET #{per_page * page}"
    tags = tags.map { |t| t.id }
    total_count = repository(:default).adapter.query("SELECT COUNT(*) FROM (SELECT COUNT(*) #{self.search_query(tags, opts)}) AS c")[0]
    page_count = (total_count / per_page) + (total_count % per_page > 0 ? 1 : 0)
    favourites = self.find_by_sql("SELECT f.id, f.name, f.description, f.created_at, f.updated_at, f.synchronized_at #{self.search_query(tags, opts)} ORDER BY f.name #{limit_clause}")
    [page_count, favourites]
  end

  # instance methods

  def creator
    self.user
  end

  def viewable_by?(user)
    self.user == user
  end

  def editable_by?(user)
    self.user == user
  end

  def removable_by?(user)
    self.user == user
  end

  def synchronize(force=false)
    # check if sync should be done
    return unless Topic.all_without_scope.get(self.topic_id).viewable_by?(self.user)
    return if self.synchronized_at && self.synchronized_at > SYNC_INTERVAL.minutes.ago.to_datetime && !force
    self.synchronized_at = Time.now
    save
    # add new elements
    element_ids = self.favourite_elements.all_without_scope.map { |favourite_element| favourite_element.element_id }
    self.topic.topic_elements.all(:element_id.not => element_ids).each do |topic_element|
      self.favourite_elements.create(:element => topic_element.element, :custom => false, :status => :fresh)
    end
    # clone removed elements
    removed_topic_elements = self.topic.topic_elements.removed.all(:element_id => element_ids)
    removed_topic_elements.each do |topic_element|
      favourite_element = self.favourite_elements.all_without_scope.first(:element_id => topic_element.element_id)
      if favourite_element.removed?
        favourite_element.destroy
      else
        favourite_element.element = topic_element.element.clone
        favourite_element.status = :removed_from_topic
        favourite_element.custom = true
        favourite_element.save
      end
    end
    # remove topic_element and element if no one else is using it
    removed_topic_elements.each do |topic_element|
      if FavouriteElement.all_without_scope.count(:element_id => topic_element.element_id) == 0
        topic_element.destroy
        topic_element.element.destroy
      end
    end
    # hide all elements that have been hidden in topic
    hidden_element_ids = self.topic.topic_elements.hidden.all.map { |te| te.element_id}
    self.favourite_elements.all(:status.not => :hidden, :element_id => hidden_element_ids).each do |favourite_element|
      favourite_element.hide!
    end
  end

  def add_custom_element(element)
    self.favourite_elements.create(:element => element, :custom => true, :status => :accepted)
  end

  protected

  def remove_associated_objects
    # remove favourite_elements and custom elements
    custom_elements = Element.all(:id => self.favourite_elements.all(:custom => true).map { |fe| fe.element_id })
    self.favourite_elements.destroy!
    custom_elements.destroy! unless custom_elements.empty?
  end
end
