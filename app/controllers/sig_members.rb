class SigMembers < SigMembersBase
  before :ensure_topic_owner_or_admin, :exclude => [:accept, :reject]
  before :ensure_not_private_topic, :only => [:create, :update]

end
