class Application < Merb::Controller
  before :prevent_caching
  
  def self.is_admin_controller
    before :ensure_admin
    self.class_eval do
      def menu_type
        "admin"
      end
      def resource_path(*args)
        args = [:admin] + args
        resource(*args)
      end
    end
  end

  def ensure_admin
    raise Forbidden unless session.user.admin?
  end

  def menu_type
    "user"
  end

  def sanitize_keywords
    params[:q] = params[:q].to_s.strip.gsub('%', '')
  end

  def resource_path(*args)
    resource(*args)
  end

  def template_path(tpl)
    tpl
  end

  protected

  def prevent_caching
    headers["Cache-Control"] = "private, max-age=0, must-revalidate"
  end

end