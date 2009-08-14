class Tag
  include DataMapper::Resource

  property :id,                         Serial
  property :name,                       String, :nullable => false, :unique => true, :unique_index => true
  property :non_private_topics_count,   Integer, :default => 0
  property :non_private_elements_count, Integer, :default => 0

  has n, :topic_tags
  has n, :topics, :through => :topic_tags
  has n, :element_tags
  has n, :elements, :through => :element_tags
  has n, :bookmark_tags
  has n, :bookmarks, :through => :bookmark_tags
  has n, :favourite_tags
  has n, :user_tag_stats

  # class methods

  def self.validate_tags(tag_names, user, users_topics_only=false)
    tag_names = tag_names.map { |t| t.downcase }
    # find existing tags
    tags = Tag.all(:name => tag_names.reject { |t| t.blank? }.uniq, :order => [:name])
    # leave only tags that provide results for current user (removes tags from private topics)
    valid_tags = tags.select { |t| Topic.search_results_count([t], :user => user, :users_topics_only => users_topics_only) > 0 }
    invalid_tags = (tag_names - valid_tags.map { |t| t.name }).sort
    [valid_tags, invalid_tags]
  end

  def self.validate_all_tags(tag_names, user, opts={})
    tag_names = tag_names.map { |t| t.downcase }
    # find existing tags
    tags = Tag.all(:name => tag_names.reject { |t| t.blank? }.uniq, :order => [:name])
    # leave only tags that provide any results
    valid_tags = tags.select { |t| Topic.search_results_count([t], :hidden => !!opts[:hidden]) > 0 }
    invalid_tags = (tag_names - valid_tags.map { |t| t.name }).sort
    [valid_tags, invalid_tags]
  end

  def self.search(opts)
    order = opts[:order] or raise ArgumentError, "You must provide order when searching for tags!"
    limit = opts[:limit] || 100 #or raise ArgumentError, "You must provide limit when searching for tags!"
    joins = []
    wheres = []
    wheres << "tags.name LIKE '#{opts[:like]}%'" if opts[:like]
    joins += [*opts[:join]].compact
    wheres += [*opts[:where]].compact
    where_clause = wheres.empty? ? "" : "WHERE (#{wheres.join(') AND (')})"
    sql = "SELECT DISTINCT tags.id, tags.name, tags.non_private_topics_count, tags.non_private_elements_count " +
          "FROM tags #{joins.join(' ')} #{where_clause} ORDER BY #{order} LIMIT #{limit}"
    Tag.find_by_sql(sql)
  end

  def self.search_in(from, context, opts)
    type = from.to_s[0...-1] # withouts trailing 's'
    opts[:join] = ["INNER JOIN #{type}_tags ON (tags.id = #{type}_tags.tag_id)",
                   "INNER JOIN #{type}s ON (#{type}_tags.#{type}_id = #{type}s.id)"] + (opts[:join] || [])
    unless context.empty?
      tag_ids = context.map { |tag| tag.id }
      inner_query = "SELECT o.id FROM #{type}s o INNER JOIN #{type}_tags ot ON (o.id = ot.#{type}_id) " +
                    "WHERE ot.tag_id IN (#{tag_ids.join(',')}) GROUP BY o.id HAVING COUNT(*) = #{tag_ids.size}"
      opts[:where] ||= []
      opts[:where] << "#{type}_tags.tag_id NOT IN (#{tag_ids.join(",")})"
      opts[:where] << "#{type}s.id IN (#{inner_query})"
    end
    search(opts)
  end

  def self.search_in_favourites(context, user, opts={})
    opts.merge!({ :join => ["INNER JOIN user_tag_stats uts ON (uts.user_id = #{user.id} AND uts.tag_id = tags.id)"],
                  :where => ["favourites.user_id = #{user.id}"],
                  :order => "uts.usage_in_favourites DESC, tags.name" })
    search_in(:favourites, context, opts)
  end

  def self.search_in_bookmarks(context, user, opts={})
    opts.merge!({ :join => ["INNER JOIN user_tag_stats uts ON (uts.user_id = #{user.id} AND uts.tag_id = tags.id)"],
                  :where => ["bookmarks.user_id = #{user.id}"],
                  :order => "uts.usage_in_bookmarks DESC, tags.name" })
    search_in(:bookmarks, context, opts)
  end

  def self.search_in_users_topics(context, user, opts={})
    opts.merge!({ :join => ["INNER JOIN sig_members ON (topics.id = sig_members.topic_id)"],
                  :where => ["sig_members.user_id = #{user.id}", "sig_members.accepted = TRUE", "topics.status = #{Topic.status_id(:visible)}"],
                  :order => "tags.non_private_topics_count DESC, tags.name" })
    search_in(:topics, context, opts)
  end

  def self.search_in_topics(context, user, opts={})
    opts.merge!(:order => "tags.non_private_topics_count DESC, tags.name")
    access_level = "topics.access_level <> #{Topic.private_access_level} "
    unless user.guest?
      opts[:join] = ["LEFT OUTER JOIN sig_members ON (topics.id = sig_members.topic_id)"]
      access_level << "OR sig_members.user_id = #{user.id}"
    end
    opts[:where] = [access_level, "topics.status = #{Topic.status_id(:visible)}"]
    search_in(:topics, context, opts)
  end

  def self.search_in_all_topics(context, user, opts={})
    opts.merge!(:order => "tags.non_private_topics_count DESC, tags.name")
    opts[:where] = [opts[:hidden] ? "topics.status = #{Topic.status_id(:hidden)}" : "topics.status = #{Topic.status_id(:visible)}"]
    search_in(:topics, context, opts)
  end

  def self.search_in_topic_elements(topic, context, opts={})
    opts.merge!({ :join => ["INNER JOIN topic_elements ON (elements.id = topic_elements.element_id)",
                            "INNER JOIN topics ON (topic_elements.topic_id = topics.id)"],
             :where => ["topics.id = #{topic.id}", opts[:hidden] ? "topic_elements.status = #{TopicElement.status_id(:hidden)}" : "topic_elements.status = #{TopicElement.status_id(:visible)}"],
             :order => "tags.non_private_elements_count DESC, tags.name" })
    search_in(:elements, context, opts)
  end

  def self.search_in_favourite_elements(favourite, context, opts={})
    opts.merge!({ :join => ["INNER JOIN favourite_elements ON (elements.id = favourite_elements.element_id)",
                            "INNER JOIN favourites ON (favourite_elements.favourite_id = favourites.id)"],
             :where => ["favourites.id = #{favourite.id}", "favourite_elements.status IN (#{FavouriteElement.status_id(:accepted)}, #{FavouriteElement.status_id(:removed_from_topic)})"],
             :order => "tags.non_private_elements_count DESC, tags.name" })
    search_in(:elements, context, opts)
  end

  def self.[](name)
    self.first(:name => name)
  end

  # instance methods

  def recount_usage_in_topics
    self.non_private_topics_count = TopicTag.count(:tag_id => self.id, TopicTag.topic.status => :visible, TopicTag.topic.access_level.not => :private)
    save
  end

  def recount_usage_in_elements
    self.non_private_elements_count = ElementTag.count(:tag_id => self.id, ElementTag.element.topic_element.status => :visible,
                                      ElementTag.element.topic_element.topic.access_level.not => :private,
                                      ElementTag.element.topic_element.topic.status => :visible)
    save
  end

  def update_users_favourites_stats(user)
    tag_stat = user.user_tag_stats.first(:tag_id => self.id) || UserTagStat.new(:user => user, :tag => self)
    tag_stat.usage_in_favourites = user.favourite_tags.count(:tag_id => self.id)
    tag_stat.save
  end
  
  def update_users_bookmarks_stats(user)
    tag_stat = user.user_tag_stats.first(:tag_id => self.id) || UserTagStat.new(:user => user, :tag => self)
    tag_stat.usage_in_bookmarks = user.bookmark_tags.count(:tag_id => self.id)
    tag_stat.save
  end

end
