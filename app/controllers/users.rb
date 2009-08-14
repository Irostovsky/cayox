class Users < Application

  before :load_user, :only => [:edit, :update]
  before :load_ownership_requests, :only => [:edit, :update]
  before :ensure_owner, :only => [:edit, :update]
  before :load_adoptables, :only => [:edit, :show, :update]  
    
  def new
    @user = User.new
    request.xhr? ? render(:layout => false) : render
  end

  def create(user)
    @user = User.new(user)
    if @user.save
      url = url(:complete_registration_users)
      request.xhr? ? url : redirect(url)
    else
      request.xhr? ? render(:new, :layout => false) : render(:new)
    end
  end

  def edit
    @user.name = @user.full_name = @user.password = "" if @user == session.user && @user.name == @user.email
    render
  end

  def update(user)
    @user.attributes = user
    if @user.save
      redirect url(:home), :message => { :notice => _("Your profile has been updated.") }
    else
      render :edit
    end
  end

  def request_password(email=nil)
    if email
      user = User.first(:email => email)
      if user
        if user.blocked?
          message[:error] = _("Sorry, your account has been blocked")
          partial :request_password
        elsif !user.active?
          message[:error] = _("Sorry, you need to activate your account first")
          partial :request_password
        else
          user.generate_password_reset_token
          url(:password_reset_details_users)
        end
      else
        message[:error] = _("Couldn't find user with email %s") % [email]
        partial :request_password
      end
    else
      partial :request_password
    end
  end

  def activate(token)
    user = User.first(:activation_token => token, :blocked => false)
    if user
      user.activate!
      session.user = user
      if user.invited?
        redirect resource(user, :edit, :change_password => "1"), :message => { :notice => _("Thanks! Your account has been activated. Now please set your screenname, full name and password.") }
      else
        redirect url(:home), :message => { :notice => _("Thanks! Your account has been activated.") }
      end
    else
      redirect url(:home), :message => { :error => _("Invalid activation link or account has already been activated") }
    end
  end

  def reset_password(token)
    user = User.first(:password_reset_token => token)
    if user
      PasswordResetNotification.all(:user_id => user.id).destroy!
      if user.password_reset_token_expires_at < DateTime.now # FIXME expired? on user model
        redirect url(:home), :message => { :error => _("Sorry, your password reset token has expired") }
      else
        session.user = user
        user.password_reset_token = user.password_reset_token_expires_at = nil
        user.save
        redirect resource(user, :profile, :change_password => "1"), :message => { :notice => _("Please set your new password") }
      end
    else
      redirect url(:home), :message => { :error => _("Invalid password reset link or password has already been reset") }
    end
  end

  def resend_activation(email = nil)
    if email
      user = User.first(:email => email, :blocked => false) 
      if user && !user.active?
        user.send_welcome_mail
        message[:notice] = _("Activation mail sent")
        return url(:complete_resending_activation_users)
      else
        if user && user.active?
          message[:error] = _("User already active")
        elsif User.first(:email => email, :blocked => true)
          message[:error] = _("User blocked")
        else
          message[:error] = _("Error while resending activation mail")
        end
        partial :activation_mail_request
      end
    else
      partial :activation_mail_request
    end
  end

  def complete_resending_activation
    message[:notice] = _("Activation mail sent")
    render "", :layout => :homepage
  end

  def complete_registration
    message[:notice] = _("Thanks for registering! Now, activate your account by clicking on the link we've sent you via email.")
    render "", :layout => :homepage
  end

  def password_reset_details
    message[:notice] = _("Email with password reset instructions has been sent to provided email address.")
    render "", :layout => :homepage
  end
 
protected

  def load_user
    @user = User.get(params[:id]) or raise NotFound
  end

  def load_ownership_requests
    @ownership_requests = SigMember.all(:user_id => @user.id, SigMember.topic.status => :visible).pending # TODO: change to @user.sig_members.pending after updating DM
  end

  def ensure_owner
    raise Forbidden unless session.user == @user
  end
  
  def load_adoptables
    @adoptables = Topic.adoptables
  end
  
end
