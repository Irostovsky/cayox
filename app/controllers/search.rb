class Search < TopicsBase

  # index action is inherited from TopicsBase
  def index(tags=[])
    session[:mytopics] = false
    super(tags)
  end

  def home
    render :layout => :homepage
  end

  def all_tags(q, limit=10, tags=[])
    AllTagSearch.new(q, limit, tags).find
  end

  protected

  def get_topics(tags)
    Topic.search(tags, :user => session.user, :page => pagination_page, :per_page => session.user.search_results_per_page)
  end

  def get_topic_tags(tags, limit)
    Tag.search_in_topics(tags, session.user, :limit => limit)
  end

  def validate_tags(tags, user)
    Tag.validate_tags(tags, user)
  end

  def tags_autocomplete(q, limit=10, tags=[])
    TopicTagSearch.new(q, limit, tags, session.user).find
  end

end
