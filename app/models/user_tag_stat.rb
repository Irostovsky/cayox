class UserTagStat
  include DataMapper::Resource

  property :id, Serial
  property :user_id,             Integer, :nullable => false, :index => true
  property :tag_id,              Integer, :nullable => false, :index => true
  property :usage_in_favourites, Integer, :nullable => false, :default => 0
  property :usage_in_bookmarks,  Integer, :nullable => false, :default => 0

  belongs_to :user
  belongs_to :tag
end
