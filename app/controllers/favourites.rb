class Favourites < Application
  before :ensure_authenticated
  before :load_favourite, :only => [:show, :edit, :update, :destroy, :fresh, :confirm_fresh, :element_tags_autocomplete]
  before :ensure_can_access_favourite, :only => [:show, :edit, :update, :destroy, :fresh, :confirm_fresh]
  before :sanitize_keywords, :only => :tags_autocomplete

  def index(tags=[])
    # tags
    valid_tags = Tag.all(:name => tags)
    @selected_tags = valid_tags.map { |tag| tag.name }
    @all_tags = Tag.search_in_favourites(valid_tags, session.user, :limit => 50)
    # favourites
    @page_count, @favourites = Favourite.search(valid_tags, :user => session.user, :per_page => session.user.search_results_per_page, :page => pagination_page)
    render
  end

  def show(tags=[])
    @favourite.synchronize
    # tags
    valid_tags = Tag.all(:name => tags.reject { |t| t.blank? }.uniq, :order => [:name])
    @selected_tags = valid_tags.map { |t| t.name }
    @all_tags = Tag.search_in_favourite_elements(@favourite, valid_tags, :limit => 50)
    # elements
    @page_count, @elements = Element.search(valid_tags, :favourite => @favourite, :page => pagination_page, :per_page => session.user.elements_per_page)
    render
  end

  def create(topic_id)
    topic = Topic.get(topic_id) or raise NotFound
    raise Forbidden unless topic.access_level == :public || session.user.topics.include?(topic)
    raise BadRequest if session.user.topics_from_favourites.include?(topic)
    favourite = Favourite.create_from_topic(topic, session.user, language_from_headers)
    redirect resource(favourite), :message => { :notice => _("Topic '#{favourite.name}' has been added to your favourites.") }
  end

  def edit
    partial :edit_favourite_form
  end

  def update(favourite)
    if @favourite.update_attributes(favourite)
      resource(@favourite)
    else
      partial :edit_favourite_form
    end
  end

  def fresh
    @page_count, @elements = @favourite.new_elements.paginated(:order => [:created_at], :page => pagination_page, :per_page => 10)
    if @elements.empty?
      redirect resource(@favourite)
    else
      render
    end
  end

  def confirm_fresh(element_ids=[])
    new_elements = @favourite.favourite_elements.fresh.all(:element_id => element_ids)
    if params[:add]
      new_elements.each { |ne| ne.accept! }
      message_text = _("Selected new elements have been added to favourite.")
    else
      new_elements.each { |ne| ne.remove! }
      message_text = _("Selected new elements have been rejected.")
    end
    redirect(resource(@favourite, :fresh), :message => { :notice => message_text })
  end

  def destroy
    @favourite.destroy
    redirect resource(:favourites)
  end

  def tags_autocomplete(q, limit=10, tags=[])
    FavouriteTagSearch.new(q, limit, tags, session.user).find
  end

  def element_tags_autocomplete(q, limit=10, tags=[])
    ElementTagSearch.new(q, limit, tags, session.user, @favourite).find
  end

protected

  def load_favourite
    @favourite = Favourite.get(params[:id]) or raise NotFound
  end

  def ensure_can_access_favourite
    raise Forbidden unless @favourite.user == session.user
  end
end
