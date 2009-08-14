class MerbAuthSlicePassword::Sessions < MerbAuthSlicePassword::Application
  
  def update
    topic_id = session[:return_to].to_s.split(/^\/topics\/(\d+)\/join/)[1]
    if topic_id
      @topic = Topic.get(topic_id)
      params[:id] = topic_id
      if @topic.users.include?(session.user)
        session[:return_to] = resource(@topic)
      else
        partial("topics/join_group")
      end
    else
      ""
    end
  end
  
  private
  # @overwritable
  def redirect_after_login
    if request.xhr?
      ""
    else
      redirect_back_or "/", :ignore => [slice_url(:login), slice_url(:logout)]
    end
  end

  # @overwritable
  def redirect_after_logout
    message[:notice] = _("You have been logged out.")
#    redirect "/", :message => message
    redirect_back_or "/", :message => message, :ignore => [slice_url(:login), slice_url(:logout)]
  end
  
end