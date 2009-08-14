module Admin
  class Users < Application
    is_admin_controller
    before :load_user, :only => [:edit, :update, :block, :unblock, :remove, :password_reset_link]

    provides :xml

    def index(page = nil, query = nil, order = nil, active = nil, inactive = nil, blocked = nil)
      operands = { :per_page => Cayox::CONFIG[:users_per_page] , :order => [:name] }
      operands.merge!(:page => page.to_i) if page
      if query.to_s !~ /@/
        operands.merge!(:name.like => "#{query}%")
      else
        operands.merge!(:email.like => "#{query}%")
      end
      operands.merge!(:order => [order.to_sym.asc] ) if order
      if active == "1" && inactive == "0" && blocked == "0"
        operands.merge!(:activated_at.not => nil, :blocked => false)
      elsif active == "0" && inactive == "1" && blocked == "0"
        operands.merge!(:activated_at => nil)
      elsif active == "0" && inactive == "0" && blocked == "1"
        operands.merge!(:blocked => true)
      elsif active == "0" && inactive == "0" && blocked == "0"
        #NONE
      elsif active == "0" && inactive == "1" && blocked == "1"
        operands.merge!(:conditions => ["(blocked = ? or activated_at IS NULL)",true])
      elsif active == "1" && inactive == "0" && blocked == "1"
        operands.merge!(:conditions => ["(blocked = ? or activated_at IS NOT NULL)",true])
      elsif active == "1" && inactive == "1" && blocked == "0"
        operands.merge!(:blocked => false)
      end
      @page_count, @users = User.paginated operands
      render
    end

    def promote_to_admin(id)
      user = User.get(id)
      user.admin = true
      if user.save
        redirect resource(:admin, :users), :message => { :notice => _("#{user.name} promoted to admin") }
      else
        redirect resource(:admin, :users), :message => { :error => _("Could not promote user to admin, check if profile is valid") }
      end
    end

    def demote_from_admin(id)
      user = User.get(id)
      if user == session.user
        redirect resource(:admin, :users), :message => { :error => _("Admin can't demote himself") }
      else
        user.admin = false
        user.save
        redirect resource(:admin, :users), :message => { :notice => _("#{user.name} demoted to user") }
      end
    end

    def edit
      render
    end

    def update(user)
      if @user.update_attributes(user)
        redirect resource(:admin, :users), :message => { :notice => _("User updated.") }
      else
        render :edit
      end
    end

    def block
       if @user == session.user
         redirect resource(:admin, :users), :message => { :error => _("Can't block self") }
       else
         @user.blocked = true
         if @user.save
           redirect resource(:admin, :users), :message => { :notice => _("User blocked") }
         else
           redirect redirect(:admin, :users), :message => { :error => _("Could not block user, check if profile is valid") }
         end
       end
    end

    def unblock
       if @user == session.user
         redirect resource(:admin, :users), :message => { :error => _("Can't unblock self") }
       else
         @user.blocked = false
         if @user.save
           redirect resource(:admin, :users), :message => { :notice => _("User unlocked") }
         else
           resource resource(:admin, :users), :message => { :error => _("Error while unblocking uer, check if profile is valid") }
         end
       end
    end

    def send_welcome_mail(id)
      u = User.get(id)
      u.send_welcome_mail
      redirect resource(:admin, :users), :message => { :notice => _("User activation mail sent") }
    end

    def remove
      @user.remove!(session.user)
      redirect resource(:admin, :users), :message => { :notice => _("User '%s' has been permanently removed from the system.") % @user.name }
    end

    def password_reset_link
      @user.generate_password_reset_token
      redirect resource(:admin, :users), :messge => { :notice => _("Mail with password reset link sent") }
    end

    def test
      p '***************************** TEST*********************'
      render
    end

    protected

    def load_user
      @user = User.get(params[:id]) or raise NotFound
    end

  end
end