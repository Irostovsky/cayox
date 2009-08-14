require Merb.root / 'app' / 'models' / 'sig_member.rb'

class SigMemberObserver
  include DataMapper::Observer

  observe ::SigMember

  after :create do
    unless self.role == :owner && Topic.all_without_scope.get(self.topic_id).sig_members.count == 1
      RoleAssignedNotification.create(:user => self.user, :data => { :role => self.role, :topic_id => self.topic_id })
    end
  end

  after :update do
    unless @accepted_by_user
      RoleChangedNotification.create(:user => self.user, :data => { :role => self.role, :topic_id => self.topic_id })
    end
  end
  
  after :destroy do
    unless @rejected_by_user
      RoleRemovedNotification.create(:user => self.user, :data => { :role => self.role, :topic_id => self.topic_id })
    end
  end
end
