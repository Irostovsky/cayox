class Friends < Application # FIXME change controller name to Friendships

  before :ensure_authenticated
  before :load_user_friendship, :only => [ :cancel, :reject ]

  def index(page = 1)
    @pending_friendships = session.user.pending_friendships
    @requested_friendships = session.user.requested_friendships
    operands = { :per_page => Cayox::CONFIG[:friends_per_page], :page => page.to_i }
    @page_count, @friendships = session.user.friendships.paginated operands
    render
  end
  
  def new
    @invitation_form = InvitationForm.new
    request.xhr? ? partial(:new_friend) : render 
  end
  
  def create(invitation_form)
    @invitation_form = InvitationForm.new(invitation_form)
    if @invitation_form.valid_for?(session.user)
      email = @invitation_form.email
      new_friend = User.first(:email => email) || User.invite(email, session.user)
      session.user.add_friend(new_friend)
      request.xhr? ? "" : (redirect resource(:friends), :message => { :notice => _("Friend invited") } )
    else
      request.xhr? ? partial(:new_friend) : (render :new)
    end
  end
  
  def accept
    @friendship = Friendship.first(:id => params[:id], :friend_id => session.user.id)
    if @friendship
      @friendship.accept!
      redirect resource(:friends), :message => { :notice => _("Friendship request accepted") }
    else
      redirect resource(:friends), :message => { :error => _("Sorry this friendship doesn't exist") }
    end
  end
  
  def cancel
    @friendship.cancel!
    redirect resource(:friends), :message => { :notice => _("Friendship canceled") }
  end
  
  def reject
    unless @friendship.accepted?
      @friendship.reject
      redirect resource(:friends), :message => { :notice => _("Invitation canceled") }
    else
      redirect resource(:friends), :message => { :error => _("This friendship was accepted, use cancel to break it") }
    end
  end
  
  def break
    @friendship = Friendship.first(:id => params[:id], :friend_id => session.user.id)
    if @friendship
      unless @friendship.accepted?
        @friendship.reject
        redirect resource(:friends), :message => { :notice => _("Friendship request rejected") }
      else
        redirect resource(:friends), :message => { :error => _("This friendship was accepted, use cancel to break it") }
      end
    else
      render _("Sorry this friendship doesn't exist")
    end
  end
  
  def destroy # FIXME move cancel and reject to destroy
    
  end
  
  protected
  
  def load_user_friendship
    @friendship = Friendship.first(:id => params[:id], :user_id => session.user.id)
    raise NotFound unless @friendship
  end
    
end