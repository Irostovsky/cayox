class ElementTag
  include DataMapper::Resource

  property :id,         Serial
  property :tag_id,     Integer, :nullable => false, :index => true
  property :element_id, Integer, :nullable => false, :index => true

  belongs_to :tag
  belongs_to :element

  # hooks

  after :create,  :recount_usage
  after :destroy, :recount_usage

  # instance methods

protected
  def recount_usage
    tag.recount_usage_in_elements if element.topic
  end
end