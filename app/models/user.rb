require Merb.root / 'app' / 'models' / 'sig_member.rb'

class User
  include DataMapper::Resource
  include DataMapper::Is::Paginated

  EMPTY_PASS = "------"
  
  # properties
  
  property :id,                   Serial
  property :name,                 String,  :nullable => false, :index => true,
                                           :messages => { :presence => GetText._("Screenname must not be blank") }
  property :full_name,            String,  :nullable => false, :length => 100,
                                           :message => GetText._("Full name must not be blank")
  property :email,                String,  :nullable => false, :format => :email_address, :index => true,
                                           :message => GetText._("Email has an invalid format")
  property :admin,                Boolean, :nullable => false, :default => false
  property :activated_at,         DateTime
  property :activation_token,     String
  property :blocked,              Boolean, :nullable => false, :default => false
  property :primary_language_id,  Integer
  property :secondary_languages,  Json
  property :created_at,           DateTime
  property :updated_at,           DateTime
  property :last_login,           DateTime
  property :password_reset_token, String
  property :password_reset_token_expires_at, DateTime
  property :search_results_per_page, Integer
  property :elements_per_page,    Integer
  property :inviter_id,           Integer

  # validations

  validates_is_unique :name, :message => GetText._("Screen name is already taken")
  validates_length :name, :in => (3..20), :message => GetText._("Screenname must be 3-20 characters long"), :if => proc { |m| !m.invited? || !m.new_record? && m.active? }
  validates_format :name, :with => /^[\w_\.-]+$/, :message => GetText._("Screenname has an invalid format"), :if => proc { |m| !m.invited? || !m.new_record? && m.active? }
  validates_is_unique :email, :message => GetText._("Email is already taken")
  validates_length :password, :min => 6 , :if => :password_required?, :message => GetText._("Password must be at least 6 characters long")

  validates_present      :password, :if => proc { |m| m.password_required? || m.password_change_required? }, :message => GetText._("Password must not be blank")
  validates_is_confirmed :password, :if => proc { |m| m.password_required? || m.password_change_required? }, :message => GetText._("Password does not match the confirmation")

  # associations

  belongs_to :primary_language, :class_name => "Language", :child_key => [:primary_language_id]
  belongs_to :inviter, :class_name => "User", :child_key => [:inviter_id]

  has n, :sig_members
  has n, :topics, :through => :sig_members, SigMember.properties[:accepted] => true
  has n, :all_topics, :through => :sig_members, :class_name => "Topic", :child_key => [:user_id], :remote_name => :topic
  has n, :owned_topics, :through => :sig_members, :class_name => "Topic", :child_key => [:user_id], :remote_name => :topic, SigMember.properties[:role] => :owner, SigMember.properties[:accepted] => true
  has n, :maintained_topics, :through => :sig_members, :class_name => "Topic", :child_key => [:user_id], :remote_name => :topic, SigMember.properties[:role] => :maintainer
  has n, :consumed_topics, :through => :sig_members, :class_name => "Topic", :child_key => [:user_id], :remote_name => :topic, SigMember.properties[:role] => :consumer
  has n, :editable_topics, :through => :sig_members, :class_name => "Topic", :child_key => [:user_id], :remote_name => :topic, SigMember.properties[:role] => [:owner, :maintainer]
  has n, :bookmarks
  has n, :bookmark_tags, :through => :bookmarks
  has n, :messages
  has n, :friendships, :accepted => true
  has n, :pending_friendships, :accepted => false, :class_name => "Friendship"
  has n, :requested_friendships, :child_key => [:friend_id], :accepted => false, :class_name => "Friendship"
  has n, :friends, :through => :friendships, :class_name => "User", :child_key => [:user_id]
  has n, :user_languages
  has n, :secondary_languages, :through => :user_languages, :class_name => "Language", :child_key => [:user_id], :remote_name => :language
  has n, :element_votes
  has n, :favourites
  has n, :favourite_elements, :through => :favourites
  has n, :topics_from_favourites, :through => :favourites, :class_name => "Topic", :child_key => [:user_id], :remote_relationship_name => :topic
  has n, :favourite_tags, :through => :favourites
  has n, :user_tag_stats
  has n, :membership_requests
  has n, :topic_votes
  has n, :notifications
  has n, :topic_flags
  has n, :topic_element_flags
  
  # pagination

  is :paginated

  # hooks

  before :create do
    self.activation_token = self.generate_token
  end

  after :create do
    self.send_welcome_mail
  end

  # class methods

  def self.authenticate(login, password)
    param = login.include?("@") ? :email : :name
    @u = first(param => login)
    @u && @u.authenticated?(password) ? @u : nil
  end

  def self.invite(email, inviter)
    u = create(:email => email, :name => email, :full_name => email, :inviter_id => inviter.id, :password => EMPTY_PASS, :password_confirmation => EMPTY_PASS)
    u.update_attributes(:password => nil, :crypted_password => EMPTY_PASS)
    u
  end

  # instance methods

  def activate!
    if self.invited?
      InvitationNotification.all(:user_id => self.id).destroy!
    else
      RegistrationNotification.all(:user_id => self.id).destroy!
    end
    self.activated_at = Time.now
    self.activation_token = nil
    save
  end

  def generate_token
    Digest::SHA1.hexdigest("-#{name}-#{Time.now}-")
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def guest?
    false
  end

  def active?
    !!self.activated_at && !self.attribute_dirty?(:activated_at)
  end

  def admin?
    self.admin
  end

  def blocked?
    self.blocked
  end

  def invited?
    !!self.inviter_id
  end

  def status
    return "blocked" if self.blocked?
    return "active" if self.active?
    "inactive"
  end

  def search_results_per_page
    attribute_get(:search_results_per_page) || Cayox::CONFIG[:search_results_per_page]
  end

  def elements_per_page
    attribute_get(:elements_per_page) || Cayox::CONFIG[:elements_per_page]
  end

  def editable_by?(user)
    self == user || user.admin?
  end

  def friend_of?(other_user)
    self.friends.count(Friendship.properties[:accepted] => true, Friendship.properties[:friend_id] => other_user.id) > 0
  end

  def add_friend(friend, is_accepted=false)
    f = self.friendships.create(:friend_id => friend.id, :accepted => false)
    f.accept! if is_accepted
    f
  end

  def generate_password_reset_token
    self.password_reset_token = self.generate_token
    self.password_reset_token_expires_at = DateTime.now + 1 # 1 = 1 day
    save!
  end
  
  after :generate_password_reset_token do
    PasswordResetNotification.create(:user => self)
  end

  def secondary_languages=(langs)
    langs = langs.reject { |lang| lang.blank? }.uniq
    self.user_languages.all.destroy!
    langs.each do |lang_id|
      self.user_languages << UserLanguage.new(:language_id => lang_id.to_i)
    end
  end

  def send_welcome_mail
    self.invited? ? InvitationNotification.create(:user => self) : RegistrationNotification.create(:user => self)
  end

  def has_pending_element_propositions?
    topic_ids = self.editable_topics.map { |t| t.id }
    return false if topic_ids.empty?
    ElementProposition.pending.count(:topic_id => topic_ids) > 0
  end

  def has_pending_reports?
    topic_ids = self.owned_topics.map { |t| t.id }
    return false if topic_ids.empty?
    TopicFlag.pending.visible.count(:topic_id => topic_ids) + TopicElementFlag.all(TopicElementFlag.topic_element.topic_id => topic_ids).pending.visible.count > 0
  end

  def preferred_content_language(content, default_lang)
    iso_code = (content.keys & [self.primary_language.try(:iso_code)]).first
    iso_code ||= (content.keys & self.secondary_languages.map { |l| l.iso_code }).first
    iso_code ||= (content.keys & [default_lang]).first
    iso_code ||= (content.keys & [Cayox::CONFIG[:fallback_language_code]]).first
    iso_code ||= content.keys.first
    iso_code
  end

  def password_change_required?
    self.crypted_password == EMPTY_PASS && !self.attribute_dirty?(:crypted_password) && !self.attribute_dirty?(:activated_at)
  end

  def remove!(new_owner=nil)
    self.remove_associated_objects(new_owner)
    self.destroy
  end

  protected

  def remove_associated_objects(new_owner=nil)
    self.topics.private.each { |t| t.remove! }
    self.sig_members.each do |sig_member|
      topic = Topic.all_without_scope.get(sig_member.topic_id)
      sig_member.destroy
      topic.add_owner(new_owner) if new_owner && topic.owners.count == 0
    end
    self.bookmarks.all.destroy!
    self.messages.all.destroy!
    Friendship.all(:user_id => self.id).destroy!
    Friendship.all(:friend_id => self.id).destroy!
    self.user_languages.all.destroy!
    self.element_votes.all.each { |ev| ev.destroy }
    self.favourites.all.each { |o| o.destroy }
    self.membership_requests.all.destroy!
    self.topic_votes.all.each { |tv| tv.destroy }
    TopicComment.all(:user_id => self.id).destroy!
    ElementComment.all(:user_id => self.id).destroy!
    self.notifications.all.destroy!
    self.topic_flags.all.destroy!
    self.topic_element_flags.all.destroy!
  end
  
end
