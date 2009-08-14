class Exceptions < Merb::Controller
  
  # handle NotFound exceptions (404)
  def not_found
    render :layout => :homepage, :format => :html
  end

  # handle NotAcceptable exceptions (406)
  def not_acceptable
    render :format => :html
  end

  def forbidden
    msg = _("Permission Denied.")
    request.xhr? ? msg : render(msg)
  end

  def unauthenticated
    if request.xhr?
      render(partial("shared/login_form"), :layout => false, :status => 401)
    else
      render :template => "search/home", :layout => :homepage
    end
  end

  def menu_type
    nil
  end
end

