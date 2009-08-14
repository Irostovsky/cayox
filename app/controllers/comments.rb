class Comments < Application

  before :ensure_authenticated, :only => [ :create ]
  
  def element_comments(element_id, page)
    @element = Element.get(element_id)
    operands = { :per_page => 5, :page => page.to_i }
    @comments_page_count, @comments = @element.comments.paginated operands
    partial "comments/element_comments"
  end
  
  def topic_comments(topic_id, page)
    @topic = Topic.get(topic_id) or raise NotFound
    operands = { :per_page => 5, :page => page.to_i }
    @comments_page_count, @comments = @topic.comments.paginated operands
    partial "comments/topic_comments"
  end
  
  def create(type,id,comment)
    
    case type
      when /^Topic$/
        topic = Topic.get(id) or raise NotFound
        topic_comment = topic.topic_comments.new(:body => comment, :user => session.user )  
        if topic_comment.save
          redirect resource( topic )
        else
          redirect resource( topic ), :message => { :error => _("Comment not valid") }
        end
        
      when /^Element$/
        element = Element.get(id) or raise NotFound
        topic = element.topic
        raise NotFound unless element.topic_element
        element_comment = element.element_comments.new( :body => comment, :user => session.user )
        if element_comment.save
          redirect resource(topic, element)
        else
          redirect resource(topic, element), :message => { :error => _("Comment not valid") }
        end
      else
        raise NotFound
    end
    
  end
  
end
