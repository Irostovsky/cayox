class SigMembersBase < Application
  before :ensure_authenticated
  before :load_topic
  before :load_sig_member, :only => [:update, :destroy, :accept, :reject]

  def index
    MembershipRequestsNotification.all(:user_id => session.user.id).destroy!
    @page_count, @sig_members = @topic.sig_members.paginated(:per_page => Cayox::CONFIG[:roles_per_page] , :page => pagination_page)
    @membership_requests = @topic.membership_requests
    @friends = session.user.friends.all(Friendship.properties[:accepted] => true) - @topic.users
    @sig_member = SigMember.new
    render template_path(:index)
  end
  
  def create(sig_member)
    email = sig_member.delete(:email).to_s.strip
    @sig_member = @topic.sig_members.new(sig_member)
    if @sig_member.user_id.to_i <= 0
      user = @sig_member.user = User.first(:email => email) || User.invite(email, session.user)
      if @topic.users.include?(user)
        redirect resource_path(@topic, :sig_members), :message => { :error =>  _("Selected user has already been assigned to this topic.")  } and return ""
      elsif @sig_member.user.errors.on(:email)
        redirect resource_path(@topic, :sig_members, :show_email => '1'), :message => { :error =>  _("Provided email has invalid format.")  } and return ""
      end
    else
      raise BadRequest unless @sig_member.user.friend_of?(session.user)
    end
    @sig_member.user.membership_requests.all(:topic_id => @topic.id).destroy!
    @sig_member.accepted = false if @sig_member.role == :owner
    @sig_member.save
    redirect(resource_path(@topic, :sig_members), :message => { :notice => _("Role '%s' has been successfully assigned to user %s.") % [_(@sig_member.role.to_s), @sig_member.user.name] })
  end

  def update(sig_member)
    raise BadRequest unless @sig_member.role != :owner || session.user.admin?
    sig_member[:accepted] = sig_member[:role] == "owner" ? false : true
    if @sig_member.role == :owner && sig_member[:role] != "owner" && @topic.owners.count == 1 && @topic.owners.first == @sig_member.user
      redirect(resource_path(@topic, :sig_members), :message => { :error => _("You can't change this role as user %s is the only owner of this topic.") % @sig_member.user.name })
    else
      @sig_member.attributes = sig_member
      if @sig_member.dirty? && @sig_member.save
        redirect(resource_path(@topic, :sig_members), :message => { :notice => _("Role for user %s has been successfully changed.") % @sig_member.user.name })
      else
        redirect(resource_path(@topic, :sig_members), :message => { :error => _("You didn't choose new role for user %s.") % @sig_member.user.name })
      end
    end
  end
  
  def destroy
    raise BadRequest unless session.user.admin? || @sig_member.role != :owner
    if @sig_member.role != :owner || @topic.owners.count > 1 || !@sig_member.accepted?
      @sig_member.destroy
      redirect(resource_path(@topic, :sig_members), :message => { :notice => _("Role '%s' has been successfully removed from user %s.") % [_(@sig_member.role.to_s), @sig_member.user.name] })
    else
      if @sig_member == @topic.sig_members.first(:user_id => session.user.id)
        redirect(resource_path(@topic, :sig_members), :message => { :error => _("Role '%s' can't be removed from you as you are the only active owner.") % _(@sig_member.role.to_s) })
      else
        @topic.add_owner(session.user)
        @sig_member.destroy
        redirect(resource_path(@topic, :sig_members), :message => { :notice => _("Role '%s' has been reassigned from user %s to you.") % [_(@sig_member.role.to_s), @sig_member.user.name] })
      end
    end
  end
  
  def accept
    raise Forbidden unless @sig_member.user == session.user
    if @topic.abandoned_at
      membership = @topic.sig_members.first(:accepted => true, :role => :owner)
      membership.destroy
      @topic.abandoned_at = nil
      @topic.save
    end
    @sig_member.accept!
    redirect(resource(session.user, :edit), :message => { :notice => _("You have accepted 'owner' role for topic '%s'.") % translate(@sig_member.topic.name) })
  end
  
  def reject
    raise Forbidden unless @sig_member.user == session.user
    @sig_member.reject!
    redirect(resource(session.user, :edit), :message => { :notice => _("You have rejected 'owner' role for topic '%s'.") % translate(@sig_member.topic.name) })
  end
  
  protected
  
  def load_topic
    if session.user.admin?
      @topic = Topic.all_without_scope.get(params[:topic_id]) or raise NotFound
    else
      @topic = session.user.all_topics.get(params[:topic_id]) or raise Forbidden
    end
  end
  
  def load_sig_member
    @sig_member = SigMember.get(params[:id]) or raise NotFound
  end

  def ensure_topic_owner_or_admin
    raise Forbidden unless @topic.owners.include?(session.user) || session.user.admin?
  end

  def ensure_not_private_topic
    raise BadRequest if @topic.private?
  end

end

