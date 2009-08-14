class MembershipRequests < Application
  before :ensure_authenticated
  before :load_topic
  before :ensure_topic_owner, :only => [:accept, :reject]
  before :load_membership_request, :only => [:accept, :reject]

  # TODO move CUG membership requesting from topics controller to this controller
#  def create(membership_request)
#  end

  def accept
    @membership_request.accept!
    redirect(resource(@topic, :sig_members), :message => { :notice => _("Accepted access to topic for user %s.") % @membership_request.user.name })
  end
  
  def reject
    @membership_request.reject!
    redirect(resource(@topic, :sig_members), :message => { :notice => _("Rejected access to topic for user %s.") % @membership_request.user.name })
  end

  protected
  
  def load_topic
    @topic = session.user.topics.get( params[:topic_id] ) or raise Forbidden
    @topic.owners.include?(session.user) or raise Forbidden
  end
  
  def load_membership_request
    @membership_request = MembershipRequest.get(params[:id])
  end

  def ensure_topic_owner
    raise Forbidden unless @topic.owners.include?(session.user)
  end

end
