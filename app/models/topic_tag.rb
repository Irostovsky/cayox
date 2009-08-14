class TopicTag
  include DataMapper::Resource

  # properties

  property :id,       Serial
  property :tag_id,   Integer, :nullable => false, :index => true
  property :topic_id, Integer, :nullable => false, :index => true

  # associations

  belongs_to :tag
  belongs_to :topic

  # hooks

  after :create,  :recount_usage
  after :destroy, :recount_usage

protected
  def recount_usage
    tag.recount_usage_in_topics
  end
end