class BookmarkTag
  include DataMapper::Resource

  # properties

  property :id,          Serial
  property :tag_id,      Integer, :nullable => false, :index => true
  property :bookmark_id, Integer, :nullable => false, :index => true

  # associations

  belongs_to :tag
  belongs_to :bookmark
  
  # hooks

  after :create, :recount_tag_usage_in_bookmarks
  after :destroy, :recount_tag_usage_in_bookmarks

  # protected

  def recount_tag_usage_in_bookmarks
    self.tag.update_users_bookmarks_stats(self.bookmark.user)
  end
  
end