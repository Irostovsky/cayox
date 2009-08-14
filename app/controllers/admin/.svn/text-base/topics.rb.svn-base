module Admin
  class Topics < TopicsBase
    is_admin_controller
    before :load_topic, :only => [:show, :element_tags_autocomplete, :block, :unblock, :remove]

    def block
      @topic.hide!
      redirect request.env['HTTP_REFERER']
    end

    def unblock
      @topic.unhide!
      redirect request.env['HTTP_REFERER']
    end

    def remove
      @topic.remove!
      redirect resource(:admin, :topics), :message => { :notice => _("Topic '%s' has been permanently removed from the system.") % translate(@topic.name) }
    end
    
    protected

    def get_topics(tags)
      Topic.search(tags, :page => pagination_page, :per_page => session.user.search_results_per_page, :hidden => !!params[:blocked])
    end
    
    def get_topic_tags(tags, limit)
      Tag.search_in_all_topics(tags, session.user, :limit => limit, :hidden => !!params[:blocked])
    end

    def get_elements(tags)
      Element.search(tags, :topic => @topic, :page => pagination_page, :per_page => session.user.elements_per_page, :hidden => !!params[:blocked])
    end

    def get_elements_tags(tags)
      Tag.search_in_topic_elements(@topic, tags, :limit => 50, :hidden => !!params[:blocked])
    end

    def validate_tags(tags, user)
      Tag.validate_all_tags(tags, user, :hidden => !!params[:blocked])
    end

    def load_topic
      @topic = Topic.all_without_scope.get(params[:id]) or raise NotFound
    end

    def tags_autocomplete(q, limit=10, tags=[])
      AdminTopicTagSearch.new(q, limit, tags, params[:blocked] == "1").find
    end

    def element_tags_autocomplete(q, limit=10, tags=[], blocked=nil)
      ElementTagSearch.new(q, limit, tags, session.user, @topic, blocked == "true").find
    end
  end
end