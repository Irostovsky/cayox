class TagSearch
  def initialize(q, limit, tags)
    @q = q
    @limit = limit
    @tags = tags
  end

  def find
    return "" if @q.empty?
    tags = perform_search
    tags.map { |t| t.name }.join("\n")
  end

  def perform_search
    raise RuntimeError, "Implement perform_search method on your search model!"
  end
end


class TopicTagSearch < TagSearch
  def initialize(q, limit, tags, user, users_topics_only=false)
    super(q, limit, tags)
    @user = user
    @users_topics_only = users_topics_only
  end

  def perform_search
    context = Tag.all(:name => @tags)
    meth = @users_topics_only ? :search_in_users_topics : :search_in_topics
    Tag.send(meth, context, @user, :like => @q, :limit => @limit)
  end
end

class AdminTopicTagSearch < TagSearch
  def initialize(q, limit, tags, hidden)
    super(q, limit, tags)
    @hidden = hidden
  end

  def perform_search
    context = Tag.all(:name => @tags)
    Tag.search_in_all_topics(context, @user, :like => @q, :limit => @limit, :hidden => @hidden)
  end
end

class ElementTagSearch < TagSearch
  def initialize(q, limit, tags, user, object, hidden=false)
    super(q, limit, tags)
    @object = object
    @hidden = hidden
  end

  def perform_search
    if @object.is_a?(Favourite)
      Tag.search_in_favourite_elements(@object, Tag.all(:name => @tags), :like => @q, :limit => @limit)
    else
      Tag.search_in_topic_elements(@object, Tag.all(:name => @tags), :like => @q, :limit => @limit, :hidden => @hidden)
    end
  end
end


class FavouriteTagSearch < TagSearch
  def initialize(q, limit, tags, user)
    super(q, limit, tags)
    @user = user
  end

  def perform_search
    Tag.search_in_favourites(Tag.all(:name => @tags), @user, :like => @q, :limit => @limit)
  end
end


class BookmarkTagSearch < TagSearch
  def initialize(q, limit, tags, user)
    super(q, limit, tags)
    @user = user
  end

  def perform_search
    Tag.search_in_bookmarks(Tag.all(:name => @tags), @user, :like => @q, :limit => @limit)
  end
end


class AllTagSearch < TagSearch
  def initialize(q, limit, tags)
    super(q, limit, tags)
  end

  def perform_search
    Tag.all(:name.like => "#{@q}%", :limit => @limit.to_i, :order => [:name])
  end
end

