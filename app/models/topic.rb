require Merb.root / 'app' / 'models' / 'sig_member.rb'
require Merb.root / 'app' / 'models' / 'comment.rb'
require Merb.root / 'app' / 'models' / 'topic_element.rb'

class Topic
  include DataMapper::Resource
  ACCESS_LEVELS = [:public, :private, :closed_user_group]
  STATUSES = [:visible, :hidden]
  
  # properties

  property :id,              Serial
  property :name,            Yaml, :lazy => false, :default => lambda { Hash.new }
  property :description,     Yaml, :lazy => false, :default => lambda { Hash.new }
  property :access_level,    Enum[*ACCESS_LEVELS], :nullable => false, :default => :public, :index => true
  property :status,          Enum[*STATUSES], :nullable => false, :default => :visible, :index => true
  property :created_at,      DateTime
  property :updated_at,      DateTime
  property :views,           Integer, :default => 0
  property :average_vote,    Float
  property :abandoned_at,    DateTime

  # default scope

  default_scope(:default).update(:status => [:visible])

  # validations
  
  validates_is_unique :name, :message => GetText._("Topic with that name already exists") , :if => Proc.new {|t| t.access_level == :public }
  
  # associations

  has n, :sig_members
  has n, :users, :through => :sig_members
  has n, :owners, :through => :sig_members, :remote_name => :user, :class_name => 'User', :child_key => [:topic_id], SigMember.properties[:role] => :owner, SigMember.properties[:accepted] => true
  has n, :maintainers, :through => :sig_members, :remote_name => :user, :class_name => 'User', :child_key => [:topic_id], SigMember.properties[:role] => :maintainer
  has n, :consumers, :through => :sig_members, :remote_name => :user, :class_name => 'User', :child_key => [:topic_id], SigMember.properties[:role] => :consumer
  has n, :editors, :through => :sig_members, :remote_name => :user, :class_name => 'User', :child_key => [:topic_id], SigMember.properties[:role] => [:maintainer, :owner]
  has n, :topic_elements
  has n, :elements, :through => :topic_elements, TopicElement.properties[:status] => :visible
  has n, :favourites
  has n, :elements_from_favourites, :through => :favourites, :class_name => "Element", :child_key => [:topic_id]
  has n, :element_propositions
  has n, :membership_requests
  has n, :pending_users, :through => :membership_requests, :class_name => 'User', :remote_name => :user, :child_key => [:topic_id]
  has n, :topic_flags
  has n, :topic_votes

  # remeber to always use enhance for relations with remix modules
  remix n, :comments

  enhance :comments do
    is :paginated
    belongs_to :user
  end

  is :paginated

  # validations

  validates_with_block :name do
    if name.empty? || name.keys.detect { |key| name[key].blank? }
      [false, GetText._("Name must not be blank")]
    elsif name.keys.detect { |key| name[key].to_s.size > 100 }
      [false, GetText._("Name must be less than 100 characters long")]
    else
      true
    end
  end

  validates_with_block :description do
    if description.keys.detect { |key| description[key].to_s.size > 1024 }
      [false, GetText._("Description must be less than 1024 characters long")]
    else
      true
    end
  end

  validates_with_block :access_level do
    self.access_level == :private && SigMember.count(:topic_id => self.id) > 1 ? [false, GetText._("You cannot set this topic to private as it has some roles assigned")] : true
    # change SigMember.count(:topic_id => self.id) to self.sig_members.count after upgrade to DM 0.10
  end

  # hooks

  before :destroy , :remove_associated_objects

  # class methods

  def self.all_without_scope
    all(:status => STATUSES)
  end

  def self.private_access_level
    1 + ACCESS_LEVELS.index(:private)
  end

  def self.private
    all(:access_level => :private)
  end

  def self.status_id(status)
    1 + STATUSES.index(status)
  end

  def self.search_query(tags, opts)
    user = opts[:user]
    wheres = []
    access_level_clause = nil
    sig_members_join = nil
    having_clause = nil
    topic_tags_join = nil
    tag_ids = tags.map { |t| t.id }
    wheres << (opts[:hidden] ? "topics.status = #{Topic.status_id(:hidden)}" : "topics.status = #{Topic.status_id(:visible)}")

    if user
      access_level_clause = "topics.access_level <> #{Topic.private_access_level} " unless opts[:users_topics_only]
      unless user.guest?
        if opts[:users_topics_only]
          sig_members_join = "INNER JOIN sig_members ON (topics.id = sig_members.topic_id)"
          access_level_clause = "(sig_members.user_id = #{user.id} AND sig_members.accepted = TRUE)"
        else
          sig_members_join = "LEFT OUTER JOIN sig_members ON (topics.id = sig_members.topic_id)"
          access_level_clause << "OR sig_members.user_id = #{user.id}"
        end
      end
      access_level_clause = "(#{access_level_clause})"
    end

    unless tags.empty?
      wheres << "tt.tag_id IN (#{tag_ids.join(',')})"
      having_clause = "HAVING COUNT(*) >= #{tag_ids.size}"
      topic_tags_join = "INNER JOIN topic_tags tt ON (topics.id = tt.topic_id)"
    end

    wheres << access_level_clause
    wheres = wheres.compact.join(" AND ")
    wheres = "WHERE #{wheres}" unless wheres.empty?

    # remember to GROUP properties in order they were defined at the top of the model (+ tags_count added by lib/tags.rb) !!!
    "FROM topics #{topic_tags_join} #{sig_members_join} #{wheres}  \
     GROUP BY topics.id, topics.name, topics.description, topics.access_level, topics.status, topics.created_at, topics.updated_at, topics.views, topics.tag_count \
     #{having_clause}"
  end

  def self.search(tags, opts={})
    per_page = opts[:per_page] || 100
    page = opts[:page].to_i
    page = page < 1 ? 1 : page
    limit_clause = "LIMIT #{per_page} OFFSET #{per_page * (page-1)}"
    order = tags.empty? ? "topics.views DESC" : "topics.tag_count, topics.views DESC"
    # remember to SELECT properties in order they were defined at the top of the model (+ tags_count added by lib/tags.rb) !!!
    total_count = self.search_results_count(tags, opts)
    page_count = (total_count / per_page) + (total_count % per_page > 0 ? 1 : 0)
    elements = self.find_by_sql("SELECT topics.id, topics.name, topics.description, topics.access_level, topics.status, topics.created_at, topics.updated_at, topics.views, topics.tag_count #{self.search_query(tags, opts)} ORDER BY #{order} #{limit_clause}")
    [page_count, elements]
  end

  def self.search_results_count(tags, opts={})
    repository(:default).adapter.query("SELECT COUNT(*) FROM (SELECT COUNT(*) #{self.search_query(tags, opts)}) AS c")[0] # we need to add another COUNT(*) to count the groups
  end

  def self.adoptables
    self.all(:abandoned_at.not => nil)
  end
  
  def self.clear_abandoned
    self.all_without_scope.all(:abandoned_at.lt => DateTime::now).map do |topic| 
        topic.destroy
    end
  end

  # instance methods

  def comments
    self.topic_comments
  end

  def viewable_by?(user)
     self.access_level == :public || self.access_level == :closed_user_group && user.topics.include?(self) || self.access_level == :private && user.owned_topics.include?(self) || user.admin?
  end

  def editable_by?(user)
    (user.owned_topics + user.maintained_topics).include?(self)
  end
  
  def user_role(user)
    self.sig_members.first(:user_id => user.id).role
  end

  def add_view_by(user)
    return if user.in?(self.owners + self.maintainers) # don't count owner and maintainer views
    self.views = self.views.to_i + 1
    self.save
  end

  def add_owner(user)
    self.sig_members.create(:user => user, :role => :owner)
  end
  
  def add_maintainer(user)
    self.sig_members.create(:user => user, :role => :maintainer)
  end

  def add_consumer(user)
    self.sig_members.create(:user => user, :role => :consumer)
  end

  def private?
    self.access_level == :private
  end

  def visible?
    self.status == :visible
  end

  def hide!
    if self.visible?
      self.status = :hidden
      save
      self.element_propositions.destroy!
      favourites_ids = self.favourites.map { |f| f.id }
      FavouriteElement.fresh.all(:favourite_id => favourites_ids).destroy! unless favourites_ids.empty?
    end
  end
  
  def unhide!
    if self.status == :hidden
      self.status = :visible
      save
    end
  end

  def remove!
    self.destroy
  end

  def vote(rate, user)
    if rate.to_i == 0
      topic_vote = user.topic_votes.first(:topic_id => self.id)
      topic_vote.destroy if topic_vote
    else
      topic_vote = user.topic_votes.first(:topic_id => self.id) || user.topic_votes.create(:topic_id => self.id)
      topic_vote.rate = rate
      topic_vote.save
    end
  end

  def recount_votes
    votes = TopicVote.all(:topic_id => self.id)
    if (c = votes.count) > 0
      res = votes.inject(0) { |result, element| result + element.rate.to_f }  # TODO: change this to votes.sum(:rate)
      self.average_vote = res.to_f / c.to_f
    else
      self.average_vote = nil
    end
    self.save
  end
  
  def permalink(lang_code)
    Cayox::CONFIG[:site_url] + "/topics/#{self.id}-#{self.name[lang_code].slug}?lang=#{lang_code}"
  end


  protected

  def remove_associated_objects
    self.sig_members.all.destroy!
    self.favourites.all.each { |o| o.destroy }
    self.topic_elements.all_without_scope.each { |o| o.remove!(true) }
    self.element_propositions.all.each { |o| o.destroy }
    self.membership_requests.all.each { |o| o.destroy }
    self.topic_flags.all.each { |o| o.destroy }
    self.topic_votes.all.each { |o| o.destroy }
    self.comments.all.each { |o| o.destroy }
  end

end
