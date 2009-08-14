class FlagsBase < Application

  before :ensure_authenticated, :exclude => [:new, :create]

  def index
    FlagsNotification.all(:user_id => session.user.id).destroy!
    @topic_flags_page_count, @topic_flags =
      TopicFlag.pending.paginated({ TopicFlag.topic.status => :visible,
                                  :order => [:created_at.desc], :per_page => 20, :page => pagination_page(:topics_page) }.merge!(topic_filtering_conditions))
    @element_flags_page_count, @element_flags =
      TopicElementFlag.pending.paginated({ TopicElementFlag.topic_element.topic.status => :visible,
                                         TopicElementFlag.topic_element.status => :visible,
                                         :order => [:created_at.desc], :per_page => 20, :page => pagination_page(:elements_page) }.merge!(element_filtering_conditions))
    render template_path(:index)
  end

  def confirm(type, flagging_ids)
    case type
    when "topics"
      flaggings = TopicFlag.visible.pending.all({ :id => flagging_ids }.merge!(topic_filtering_conditions))
    when "elements"
      flaggings = TopicElementFlag.visible.pending.all({ :id => flagging_ids, TopicElementFlag.topic_element.topic.status => :visible }.merge!(element_filtering_conditions))
    end
    if flaggings.size > 0
      if params[:reject]
        flaggings.each { |f| f.reject! }
        msg = _("Selected reports have been rejected.")
      else
        flaggings.each { |f| f.accept! }
        msg = _("Selected items have been removed.")
      end
      redirect resource_path(:flags), :message => { :notice => msg }
    else
      redirect resource_path(:flags), :message => { :error => _("Sorry, selected items haven't been found. They were accepted by another owner or topic has been removed.") }
    end
  end

  protected

  def topic_filtering_conditions
    raise RuntimeError, "Implement topic_filtering_conditions method!"
  end

  def element_filtering_conditions
    raise RuntimeError, "Implement element_filtering_conditions method!"
  end

end
