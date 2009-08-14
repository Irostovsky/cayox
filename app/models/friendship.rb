class Friendship
  include DataMapper::Resource

  # properties

  property :id, Serial
  property :user_id, Integer, :nullable => false
  property :friend_id, Integer, :nullable => false
  property :accepted, Boolean, :default => false

  belongs_to :user
  belongs_to :friend, :class_name => "User", :child_key => [:friend_id]

  validates_with_method :check_if_self
  validates_is_unique :friend_id, :scope => :user_id , :message => GetText._("Sorry invitation exists")
  validates_is_unique :user_id, :scope => :friend_id, :message => GetText._("Sorry this freindship is pending")
  
  # pagination
  is :paginated

  # hooks

  after :create do
    unless Friendship.first(:user_id => self.friend_id, :friend_id => self.user_id)
      FriendshipRequestNotification.create(:user => self.friend, :data => { :friendship_id => self.id })
    end
  end

  # instance methods
  
  def accept!
    FriendshipRequestNotification.all(:user_id => self.friend_id, :data => { :friendship_id => self.id }).destroy!
    fr = Friendship.first_or_create(:user_id => self.friend_id, :friend_id => self.user_id)
    fr.accepted = true
    fr.save
    self.accepted = true
    self.save!
  end

  def cancel!
    fr = Friendship.first(:friend_id => self.user_id, :user_id => self.friend_id)
    fr.destroy if fr # for concurent bug
    self.destroy
  end

  def reject # FIXME add ! to method name
    FriendshipRequestNotification.all(:user_id => self.friend_id, :data => { :friendship_id => self.id }).destroy!
    self.destroy
  end

  protected

  def check_if_self
    if self.user_id == self.friend_id
      return [false, GetText._("Sorry can't make freidnship with self")]
    end
    true
  end

end
