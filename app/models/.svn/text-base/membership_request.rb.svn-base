class MembershipRequest
  include DataMapper::Resource
  
  property :id, Serial
  property :created_at, DateTime
  property :sent,     Boolean, :default => false
  
  belongs_to :user
  belongs_to :topic
  
  validates_is_unique :user_id, :scope => :topic_id
  
  def self.daily_notification
    memberships_today = MembershipRequest.all(:sent => false )
    editors = memberships_today.inject([]) { |acc, membership| acc += membership.topic.owners; acc }.uniq
    editors.each do |editor|
      editor_memberships = memberships_today.select { |m| m.topic.editors.include?(editor) }
      MembershipRequestsNotification.create(:user => editor, :data => { :membership_requests_ids => editor_memberships.map { |m| m.id } })
      # mark as sent
      editor_memberships.map do |membership_request| 
        membership_request.sent = true
        membership_request.save 
      end
      
    end
  end

  def accept!
    self.topic.sig_members.create(:user_id => self.user_id, :role => :consumer)
    self.destroy
  end

  def reject!
    self.destroy
  end

end
