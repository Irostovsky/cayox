require Merb.root / 'app' / 'models' / 'comment.rb'

class Element
  include DataMapper::Resource
  
  # properties

  property :id,              Serial
  property :name,            Yaml, :lazy => false, :default => lambda { Hash.new }
  property :description,     Yaml, :lazy => false, :default => lambda { Hash.new }
  property :link_id,         Integer, :nullable => false, :auto_validation => false, :index => true
  property :created_at,      DateTime
  property :updated_at,      DateTime
  property :average_vote,    Float
  property :views,           Integer, :default => 0
  property :rank,            Float, :default => 0.0, :index => true

  # associations

  belongs_to :link
  has 1, :topic_element
  has 1, :topic, :through => :topic_element
  has n, :element_votes
  has n, :favourite_elements
  has n, :favourites, :through => :favourite_elements

  # remeber to always use enhance for relations with remix modules
  remix n, :comments

  enhance :comments do
    is :paginated
    belongs_to :user
  end

  is :paginated

  # validations

  validates_present :link
  validates_with_method :url, :method => :validate_link
  
  validates_with_block :name do
    if name.empty? || name.keys.detect { |key| name[key].blank? }
      [false, GetText._("Element name must not be blank")]
    elsif name.keys.detect { |key| name[key].to_s.size > 100 }
      [false, GetText._("Element name must be less than 100 characters long")]
    else
      true
    end
  end

  validates_with_block :description do
    if description.keys.detect { |key| description[key].to_s.size > 1024 }
      [false, GetText._("Element description must be less than 1024 characters long")]
    else
      true
    end
  end

  # hooks

  before :destroy do
    self.comments.all.destroy!
    self.element_votes.all.destroy!
  end

  # class methods

  def self.create_elements_from_bookmarks(bookmarks,topic,user,default_language=nil)
    bookmarks.map do |bookmark|
      ele = Element.create(:name => language_hash_from_string(bookmark.name, user, default_language), :description => language_hash_from_string(bookmark.description,user,default_language), :link_id => bookmark.link_id, :tag_list => bookmark.tag_list.join(","), :url => bookmark.url)
      topic.topic_elements.create(:element => ele)
    end
  end


  def self.search_query(tags, opts)
    object = opts[:topic] || opts[:favourite] or raise ArgumentError, GetText._("You must provide topic or favourite for elements search!")
    type = object.class.to_s.downcase
    tag_clause = nil
    having_clause = nil
    element_tags_join = nil
    element_visibility_clause = case type
      when "topic"
        opts[:hidden] ? "AND oe.status = #{TopicElement.status_id(:hidden)}" : "AND oe.status = #{TopicElement.status_id(:visible)}"
      when "favourite"
        "AND oe.status IN (#{FavouriteElement.status_id(:accepted)},#{FavouriteElement.status_id(:removed_from_topic)})"
      else
        ""
      end

    unless tags.empty?
      tag_clause = "AND et.tag_id IN (#{tags.join(',')})"
      having_clause = "HAVING COUNT(*) = #{tags.size}"
      element_tags_join = "INNER JOIN element_tags et ON (e.id = et.element_id)"
    end

    "FROM elements e #{element_tags_join} INNER JOIN #{type}_elements oe ON (oe.element_id = e.id) WHERE oe.#{type}_id = #{object.id} #{tag_clause} #{element_visibility_clause} \
     GROUP BY e.id, e.name, e.description, e.link_id, e.created_at, e.updated_at, e.average_vote, e.views, e.rank \
     #{having_clause}"
  end

  def self.search(tags, opts)
    per_page = opts[:per_page] || 100
    page = opts[:page].to_i
    page = page < 1 ? 1 : page
    limit_clause =  "LIMIT #{per_page} OFFSET #{per_page * (page-1)}"
    tags = tags.map { |t| t.id }
    total_count = repository(:default).adapter.query("SELECT COUNT(*) FROM (SELECT COUNT(*) #{self.search_query(tags, opts)}) AS c")[0]
    page_count = (total_count / per_page) + (total_count % per_page > 0 ? 1 : 0)
    elements = self.find_by_sql("SELECT e.id, e.name, e.description, e.link_id, e.created_at, e.updated_at, e.average_vote, e.views, e.rank #{self.search_query(tags, opts)} ORDER BY e.rank DESC #{limit_clause}")
    [page_count, elements]
  end

  # instance methods

  def comments
    self.element_comments
  end

  def url=(url)
    self.link = Link.get_by_url(url.strip)
  end

  def url
    self.link.try(:url)
  end

  def viewable_by?(user)
    self.topic && self.topic.viewable_by?(user) || (!user.guest? && !!user.favourite_elements.first(:element_id => self.id)) || user.admin?
  end

  def editable_by?(user)
    return false if user.guest?
    self.topic && self.topic.editable_by?(user) || !!user.favourite_elements.first(:element_id => self.id, :custom => true)
  end

  def removable_by?(user)
    editable_by?(user)
  end

  def vote(rate,user)
    if rate.to_i == 0
      element_vote = user.element_votes.first(:element_id => self.id, :user_id => user.id)
      element_vote.destroy if element_vote
    else
      element_vote = user.element_votes.first_or_create(:element_id => self.id, :user_id => user.id)
      element_vote.rate = rate
      element_vote.save
    end
  end
  
  def add_view_by(user)
    return if self.topic.nil? || user.in?(self.topic.owners + self.topic.maintainers) # don't count owner and maintainer views, don't count custom favourite element's views
    self.views += 1
    res = self.views / ( ( DateTime::now - self.created_at + 1 ).to_f )
    self.rank = format("%.9f", res )
    self.save
  end
  
  def votes_count
    self.element_votes.count
  end

  def custom_in_favourite?(favourite)
    !!favourite.favourite_elements.first(:element_id => self.id, :custom => true)
  end

  def proposed_for_topic?(favourite)
    fav_elem = favourite.favourite_elements.first(:element_id => self.id, :custom => true)
    return false if fav_elem.nil?
    favourite.topic && favourite.topic.element_propositions.count(:favourite_element_id => fav_elem.id) > 0
  end

  def clone
    Element.new(self.attributes.merge!(:id => nil, :tag_list => self.frozen_tag_list))
  end

protected

  def validate_link
    if self.link.try(:valid?)
      true
    else
      [false, _("URL is not valid")]
    end
  end
  
  def recount_votes
    votes = ElementVote.all(:element_id => self.id)
    if (c = votes.count) > 0
      res = votes.inject(0) {|result, element| result + element.rate.to_f } # TODO: change this to votes.sum(:rate)
      self.average_vote = res.to_f / c.to_f
    else
      self.average_vote = nil
    end
    self.save
  end
  
end
