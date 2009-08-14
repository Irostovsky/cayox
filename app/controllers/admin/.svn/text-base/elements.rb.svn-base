module Admin
  class Elements < Application
    is_admin_controller
    before :load_topic
    before :load_element, :only => [:block, :unblock, :remove]

    def block
      @topic_element.hide!
      redirect resource(:admin, @topic), :message => { :notice => _("Element '%s' has been successfully blocked.") % translate(@topic_element.name) }
    end

    def unblock
      @topic_element.unhide!
      redirect resource(:admin, @topic, :blocked_elements), :message => { :notice => _("Element '%s' has been successfully unblocked.") % translate(@topic_element.name) }
    end

    def remove
      @topic_element.remove!(true)
      redirect resource(:admin, @topic), :message => { :notice => _("Element '%s' has been permanently removed from the system.") % translate(@topic_element.name) }
    end

    protected

    def load_topic
      @topic = Topic.all_without_scope.get(params[:topic_id]) or raise NotFound
    end

    def load_element
      @topic_element = @topic.topic_elements.all_without_scope.first(:element_id => params[:id])
      @element = @topic_element.try(:element) or raise NotFound
    end

  end
end