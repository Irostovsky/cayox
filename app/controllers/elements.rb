class Elements < Application
  before :ensure_authenticated, :only => :flag
  before :load_topic_or_favourite
  before :load_element, :only => [:edit, :update, :destroy, :show, :accept, :reject, :propose, :flag, :permalink]
  before :ensure_can_see_element, :only => [:show, :permalink]
  before :ensure_can_edit_topic, :only => [:new, :create, :accept, :reject, :propose]
  before :ensure_can_edit_element, :only => [:edit, :update]
  before :load_language, :only => [:edit, :new, :create, :update]

  def show
    @element.add_view_by(session.user) #adding view for rank
    @page_count, @elements = @topic.elements.paginated(:order => [:rank.desc], :per_page => session.user.elements_per_page, :page => pagination_page)
    @comments_page_count, @comments = @element.comments.paginated(:per_page => 5, :page => 1)
    render
  end

  def new
    @element = Element.new
    partial :new_element_form
  end

  def create(element)
    lang = @language.iso_code
    @element = Element.new
    @element.name[lang], @element.description[lang] = element.delete("name"), element.delete("description")
    @element.attributes = element
    
    if @element.save
      if @topic.is_a?(Topic)
        @topic.topic_elements.create(:element => @element)
      else
        @topic.add_custom_element(@element)
      end
      LinkLanguage.add_missing_link_languages([@element.link], @language)
      resource(@topic, @element)
    else
      partial :new_element_form
    end
  end

  def edit
    provides :json

    case content_type
    when :html
      partial :edit_element_form
    when :json
      display @element
    end
  end

  def update(element)
    lang = @language.iso_code
    @element.name[lang], @element.description[lang] = element.delete("name"), element.delete("description")
    if @element.update_attributes(element)
      resource(@topic, @element)
    else
      partial :edit_element_form
    end
  end

  def destroy
    raise Forbidden unless @topic.is_a?(Topic) && @element.editable_by?(session.user) || @topic.is_a?(Favourite) && @topic.editable_by?(session.user)
    @topic.send(:"#{@topic.class.to_s.downcase}_elements").first(:element_id => @element.id).remove! # can be topic_element or favourite_element
    redirect resource(@topic), :message => { :notice => _("Element has been successfully removed.") }
  end

  def propose
    if @favourite_element.proposition
      redirect(resource(@topic, @element), :message => { :error => _("This element has already been proposed for topic '%s'.") % translate(@topic.topic.name) })
    else
      if @favourite_element.propose!
        redirect(resource(@topic, @element), :message => { :notice => _("Element '%s' has been proposed for topic '%s'.") % [translate(@element.name), translate(@topic.topic.name)] })
      else
        redirect(resource(@topic, @element), :message => { :error => _("Sorry, topic for which you want to propose this element has been removed.") })
      end
    end
  end

  def flag(reason_id=nil)
    @reasons = FlagReason.for_elements
    if request.post? && !reason_id.blank? && (@reason = FlagReason.for_elements.first(:id => reason_id))
      partial :flag_success
    else
      render :layout => false
    end
  end

  def permalink(permalink_form={})
    attrs = { :lang => session.user.preferred_content_language(@element.name, language_from_headers) }.merge!(permalink_form)
    @permalink_form = PermalinkForm.new(attrs)
    if request.post?
      if @permalink_form.valid?
        m = PermalinkMailer.new(:item => @topic_element, :form => @permalink_form, :user => session.user)
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

  protected

  def load_topic_or_favourite
    if params[:topic_id]
      @topic = Topic.get(params[:topic_id]) or raise NotFound
    elsif params[:favourite_id]
      @topic = Favourite.get(params[:favourite_id]) or raise NotFound
    end
  end

  def load_element
    if @topic.is_a?(Topic)
      @topic_element = @topic.topic_elements.first(:element_id => params[:id])
      @element = @topic_element.try(:element) or raise NotFound
    else
      @favourite_element = @topic.favourite_elements.first(:element_id => params[:id], :status.not => :removed)
      @element = @favourite_element.try(:element) or raise NotFound
    end
  end

  def ensure_can_see_element
    raise Forbidden unless @topic.viewable_by?(session.user) && @element.viewable_by?(session.user)
  end

  def ensure_can_edit_element
    raise Forbidden unless @element.editable_by?(session.user)
  end

  def ensure_can_edit_topic
    raise Forbidden unless @topic.editable_by?(session.user)
  end

  def load_language
    @language = get_language(@element)
  end
  
end
