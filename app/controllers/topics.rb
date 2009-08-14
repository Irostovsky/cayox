class Topics < TopicsBase
  before :ensure_authenticated, :exclude => [:show, :add_elements_from_bookmarks, :join, :permalink, :element_tags_autocomplete]
  before :load_topic, :only => [:show, :edit, :update, :flag, :permalink, :element_tags_autocomplete, :abandon, :adopt]
  before :ensure_can_see_topic, :only => [:show, :permalink, :element_tags_autocomplete]
  before :ensure_can_edit_topic, :only => [:edit, :update, :abandon]
  before :load_language, :only => [:edit, :new, :create, :update]
  before :add_visit, :only => [:show]

  # show action is inherited from TopicsBase

  def new
    if request.xhr?
      @topic = Topic.new
      partial :new_topic_form
    else
      render :template => "search/home", :layout => :homepage
    end
  end
  
  def create(topic)    
    bookmarks_ids = params[:bookmarks].split(",") if params[:bookmarks]
    bookmarks = Bookmark.all(:id =>  bookmarks_ids )
    lang = @language.iso_code
    @topic = Topic.new
    @topic.name[lang], @topic.description[lang] = topic.delete("name"), topic.delete("description")
    @topic.attributes = topic
    if @topic.valid?
      @topic.save
      @topic.add_owner(session.user)
      Element.create_elements_from_bookmarks(bookmarks, @topic, session.user)
      resource(@topic)
    else
      partial :new_topic_form
    end
  end

  def edit
    provides :json
    
    case content_type
    when :html
      partial :edit_topic_form
    when :json
      display @topic
    end
  end

  def update(topic)
    lang = @language.iso_code
    @topic.name[lang], @topic.description[lang] = topic.delete("name"), topic.delete("description")
    if @topic.update_attributes(topic)
      resource(@topic)
    else
      partial :edit_topic_form
    end
  end
  
  def add_elements_from_bookmarks(topic, bookmarks)
    @topic = session.user.editable_topics.get(topic)
    bookmarks = bookmarks.split(",")
    if bookmarks.empty?
      redirect resource(:bookmarks), :message => { :error => _("Please select one or more bookmarks")  } and return ""
    elsif @topic
      bookmarks = Bookmark.all(:id => bookmarks)
      Element.create_elements_from_bookmarks(bookmarks,@topic, session.user, language_from_headers)
      redirect resource(:bookmarks), :message => { :notice => _("Bookmarks added to Topic")  }
    else
      redirect resource(:bookmarks), :message => { :error => _("Error while adding bookmarks to topic")  } and return ""
    end
  end

  def join_closed_group
    if request.method == :post
      topic = Topic.get(params[:topic_id])
      MembershipRequest.create(:topic_id => topic.id, :user_id => session.user.id)
      request.xhr? ? "" : (redirect resource(:topics) )
    else
      request.xhr? ? partial(:join_group) : render
    end
  end

  def flag(flag_id=nil)
    @flags = Flag.for_topics
    if request.post? && !flag_id.blank? && (@flag = Flag.for_topics.first(:id => flag_id))
      @topic.topic_flags.create(:user_id => session.user.id, :flag_id => @flag.id)
      partial :flag_success
    elsif topic_flag = @topic.topic_flags.first(:user_id => session.user.id)
      @flag = topic_flag.flag
      partial :flag_success
    else
      render :layout => false
    end
  end

  def permalink(permalink_form={})
    attrs = { :lang => session.user.preferred_content_language(@topic.name, language_from_headers) }.merge!(permalink_form)
    @permalink_form = PermalinkForm.new(attrs)
    if request.post?
      if @permalink_form.valid?
        m = PermalinkMailer.new(:item => @topic, :form => @permalink_form, :user => session.user)
        m.dispatch_and_deliver(:permalink, :to => @permalink_form.email, :from => Cayox::CONFIG[:mail_from],
                               :subject => _("Permalink from Cayox"))
        return ""
      else
        render :layout => false
      end
    else
      render :layout => false
    end
  end

  def element_tags_autocomplete(q, limit=10, tags=[])
    ElementTagSearch.new(q, limit, tags, session.user, @topic).find
  end

  def abandon
    if @topic.private?
      @topic.destroy
      redirect resource(:mytopics) , :message => { :notice => _("Topic '%s' has been removed.") % translate(@topic.name) }
    else
      if @topic.owners.count > 1
        # abandon ownership when we have more then 1 owner
        membership = SigMember.first(:topic_id => @topic.id, :user_id => session.user.id)
        membership.destroy
        redirect resource(:mytopics) , :message => { :notice => _("Topic '%s' has been abandoned.") % translate(@topic.name) }
      else
        @topic.abandoned_at = abandon_time
        @topic.save
        redirect resource(:mytopics) , :message => { :notice => _("Topic '%s' has been moved to adoption.") % translate(@topic.name) }
      end
    end
  end
  
  def adopt
    if @topic.abandoned_at 
      previous_owner = @topic.owners.first
      membership = SigMember.first(:topic_id => @topic.id, :user_id => session.user.id)
      if membership
        membership.role = :owner
      else
        membership = SigMember.new(:topic_id => @topic.id, :user_id => session.user.id, :role => :owner)
      end
      membership.accepted = true
      membership.save
      SigMember.first(:topic_id => @topic.id, :user_id => previous_owner.id).destroy
      @topic.abandoned_at = nil
      @topic.save
      redirect resource(session.user, :edit), :message => { :notice => _("Topic adopted") }
    else
      redirect resource(session.user, :edit), :message => { :error => _("Topic could not be adopted") }
    end
  end

  protected

  def ensure_can_see_topic
    raise Forbidden unless session.user.admin? ||
                           @topic.access_level == :public ||
                           @topic.access_level == :closed_user_group && session.user.all_topics.include?(@topic) ||
                           @topic.access_level == :private && session.user.owned_topics.include?(@topic)
  end

  def ensure_can_edit_topic
    raise Forbidden unless (session.user.owned_topics + session.user.maintained_topics).include?(@topic)
  end

  def load_language
    @language = get_language(@topic)
  end

  def add_visit
    @topic.add_view_by(session.user)
  end

  def get_elements(tags)
    Element.search(tags, :topic => @topic, :page => pagination_page, :per_page => session.user.elements_per_page)
  end

  def get_elements_tags(tags)
    Tag.search_in_topic_elements(@topic, tags, :limit => 50)
  end

  def abandon_time
    span = Cayox::CONFIG[:abandon_time_span].to_i
    (span > 0)?(DateTime::now + span):(DateTime::now + 7)
  end

end
