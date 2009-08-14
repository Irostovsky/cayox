class FavouriteTag
  include DataMapper::Resource

  # properties

  property :id,                      Serial
  property :tag_id,                  Integer, :nullable => false, :index => true
  property :favourite_id,            Integer, :nullable => false, :index => true

  # associations

  belongs_to :tag
  belongs_to :favourite

  # hooks

  after :create, :recount_tag_usage_in_favourites
  after :destroy, :recount_tag_usage_in_favourites

#  protected

  def recount_tag_usage_in_favourites
    self.tag.update_users_favourites_stats(self.favourite.user)
  end
end
