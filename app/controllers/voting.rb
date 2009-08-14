class Voting < Application
  
  before :ensure_authenticated
  
  def create(element_id, rate)
    element = Element.get(element_id)
    element.vote(rate.to_i, session.user)
    ""
  end
  
  def topic_vote(topic_id, rate)
    topic = Topic.get(topic_id)
    topic.vote(rate.to_i, session.user)
    ""
  end
  
end
