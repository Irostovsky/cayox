class TopicVote
  include DataMapper::Resource
  
  property :id, Serial
  property :rate, Float, :nullable => false

  belongs_to :user
  belongs_to :topic

  after :create, :recount_votes
  after :destroy, :recount_votes

  protected

  def recount_votes
    self.topic.recount_votes
  end

end
