class PermalinkMailer < Merb::MailController
  
  def permalink
    @user = params[:user]
    @item = params[:item]
    @comment = params[:form].comment
    @lang = params[:form].lang
    @url = Cayox::CONFIG[:site_url]
    render_mail
  end
  
end
