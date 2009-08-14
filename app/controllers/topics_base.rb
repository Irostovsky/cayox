class TopicsBase < Application
  before :load_topic, :only => [:show]
  before :sanitize_keywords, :only => [:tags_autocomplete, :element_tags_autocomplete, :all_tags]

  def index(tags=[])
    valid_tags, @invalid_tags = validate_tags(tags, session.user)
    @selected_tags = valid_tags.map { |t| t.name }
    @page_count, @topics = get_topics(valid_tags)
    @topics_tags = get_topic_tags(valid_tags, 50)
    render
  end

  def show(tags=[])
    # tags
    valid_tags = Tag.all(:name => tags.reject { |t| t.blank? }.uniq, :order => [:name])
    @selected_tags = valid_tags.map { |t| t.name }
    @all_tags = get_elements_tags(valid_tags)
    # elements
    @page_count, @elements = get_elements(valid_tags)
    # comments
    @comments_page_count, @comments = @topic.comments.paginated(:per_page => 5, :page => 1)
    render
  end

  def tags_autocomplete(q, limit=10, tags=[])
    raise RuntimeError, "Implement tags_autocomplete on your custom topics controller!"
  end
  
  def element_tags_autocomplete(q, topic_id=nil, favourite_id=nil, limit=10, tags=[])
    raise RuntimeError, "Implement element_tags_autocomplete on your custom topics controller!"
  end

  protected

  def load_topic
    @topic = Topic.get(params[:id]) or raise NotFound
  end

  def get_topics(tags, users_topics_only)
    raise RuntimeError, "Implement get_topics on your custom topics controller!"
  end

  def get_topic_tags(tags, limit)
    raise RuntimeError, "Implement get_topic_tags on your custom topics controller!"
  end

  def get_elements(tags)
    raise RuntimeError, "Implement get_elements on your custom topics controller!"
  end

  def get_elements_tags(tags)
    raise RuntimeError, "Implement get_tags on your custom topics controller!"
  end

  def validate_tags(tags, user, users_topics_only)
    raise RuntimeError, "Implement validate_tags on your custom topics controller!"
  end

end
