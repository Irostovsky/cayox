class SystemMailer < Merb::MailController
  
  def system_event
    @user = params[:user]
    @body = params[:body]
    @url = Cayox::CONFIG[:site_url]
    render_mail
  end

end
