class Flags < FlagsBase
  before :load_topic_or_element, :only => [:new, :create]
  before :load_flags, :only => [:new, :create]

  def new
    if !session.user.guest? && @object_flag = @object_flags.first(:user_id => session.user.id)
      @flag = @object_flag.flag
      partial :report_status
    else
      render :layout => false
    end
  end
  
  def create(flag_id=nil)
    raise Forbidden unless @object.viewable_by?(session.user)
    if (@flag = @flags.first(:id => flag_id)) && (!session.user.guest? || (captcha_correct = recaptcha_valid?))
      @object_flag = @object_flags.create(:user_id => (session.user.guest? ? nil : session.user.id), :flag_id => @flag.id)
      partial :report_status
    else
      unless !session.user.guest? || captcha_correct
        @captcha_error = true
      end
      render :new, :layout => false
    end
  end

  protected

  def load_topic_or_element
    if params[:element_id]
      topic = Topic.first(:id => params[:topic_id])
      @object = topic.topic_elements.first(:element_id => params[:element_id])
      @object_flags = @object.topic_element_flags
    else
      @object = Topic.first(:id => params[:topic_id])
      @object_flags = @object.topic_flags
    end
  end

  def load_flags
    @flags = Flag.send(@object.is_a?(Topic) ? :for_topics : :for_elements)
  end

  def topic_filtering_conditions
    topic_ids = session.user.owned_topics.map { |t| t.id }
    topic_ids.empty? ? { :topic_id.lt => 0 } : { :topic_id => topic_ids }
  end

  def element_filtering_conditions
    topic_ids = session.user.owned_topics.map { |t| t.id }
    topic_ids.empty? ? { TopicElementFlag.topic_element.topic_id.lt => 0 } : { TopicElementFlag.topic_element.topic_id => topic_ids }
  end

end
