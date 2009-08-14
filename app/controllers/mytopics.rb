class Mytopics < TopicsBase

  before :ensure_authenticated

  # index action is inherited from TopicsBase
  def index(tags=[])
    session[:mytopics] = true # remember that we were on my topics, not on regular search, it's used for selecting menu item
    super(tags)
  end

  def home
    render :layout => :homepage
  end

  protected

  def get_topics(tags)
    Topic.search(tags, :user => session.user, :users_topics_only => true, :page => pagination_page, :per_page => session.user.search_results_per_page)
  end

  def get_topic_tags(tags, limit)
    Tag.search_in_users_topics(tags, session.user, :limit => limit)
  end

  def validate_tags(tags, user)
    Tag.validate_tags(tags, user)
  end

  def tags_autocomplete(q, limit=10, tags=[])
    TopicTagSearch.new(q, limit, tags, session.user, true).find
  end

end
