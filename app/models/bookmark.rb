class Bookmark
  include DataMapper::Resource

  # properties

  property :id,          Serial
  property :name,        String, :nullable => false, :length => 100
  property :description, Text , :lazy => false
  property :created_at,  DateTime
  property :updated_at,  DateTime

  # validations

  validates_length :description, :max => 1024, :message => GetText._("Bookmark description must be less than 1024 characters long")
  validates_is_unique :link_id, :scope => :user_id , :message => GetText._("You already have a bookmark for this link")
  validates_with_method :url, :method => :validate_link
  
  # pagination
  is :paginated
  
  # associations

  belongs_to :user
  belongs_to :link

  # instance methods

  def url=(url)
    self.link = Link.get_by_url(url.strip)
  end

  def url
    self.link.try(:url)
  end
  
  def validate_link
    if self.link.try(:valid?)
      true
    else
      [false, _("Link is not valid")]
    end
  end

  # class methods
  
  def self.search(tags, opts)
    per_page = opts[:per_page] or raise ArgumentError, GetText._("You need to specify per_page parameter!")
    page = opts[:page]-1
    limit_clause =  "LIMIT #{per_page} OFFSET #{per_page * page}"
    tags = tags.map { |t| t.id }
    total_count = repository(:default).adapter.query("SELECT COUNT(*) FROM (SELECT COUNT(*) #{self.search_query(tags, opts)}) AS c")[0]
    page_count = (total_count / per_page) + (total_count % per_page > 0 ? 1 : 0)
    bookmarks = self.find_by_sql("SELECT f.id, f.name, f.description, f.created_at, f.updated_at , frozen_tag_list #{self.search_query(tags, opts)} ORDER BY f.name #{limit_clause}")
    [page_count, bookmarks]
  end
  
  def self.search_query(tag_ids, opts)
    user = opts[:user] or raise ArgumentError, GetText._("You need to specify user for bookmark search!")
    tag_clause = nil
    having_clause = nil
    bookmark_tags_join = nil

    unless tag_ids.empty?
      bookmark_tags_join = "INNER JOIN bookmark_tags ft ON (f.id = ft.bookmark_id)"
      tag_clause = "AND ft.tag_id IN (#{tag_ids.join(',')})"
      having_clause = "HAVING COUNT(*) = #{tag_ids.size}"
    end

    "FROM bookmarks f #{bookmark_tags_join} WHERE f.user_id = #{user.id} #{tag_clause} \
     GROUP BY f.id, f.name, f.description, f.created_at, f.updated_at #{having_clause}"
  end
  
end
