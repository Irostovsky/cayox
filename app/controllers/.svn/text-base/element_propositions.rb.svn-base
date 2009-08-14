class ElementPropositions < Application
  before :ensure_authenticated

  def index
    ElementPropositionsNotification.all(:user_id => session.user.id).destroy!
    topic_ids = session.user.editable_topics.map { |t| t.id }
    if topic_ids.empty?
      redirect(url(:mytopics))
    else
      @page_count, @element_propositions = ElementProposition.pending.paginated(:topic_id => topic_ids, :order => [:created_at.desc], :per_page => 20, :page => pagination_page)
      render
    end
  end

  def confirm(element_ids=[])
    topic_ids = session.user.editable_topics.map { |t| t.id }
    if topic_ids.empty?
      redirect(url(:mytopics))
    else
      element_propositions = ElementProposition.pending.all(:id => element_ids, :topic_id => topic_ids)
      if element_propositions.size > 0
        if params[:add]
          element_propositions.each do |ep|
            ep.accept!
          end
          message_text = _("Selected elements have been added to respective topics.")
        else
          element_propositions.each do |ep|
            ep.reject!
          end
          message_text = _("Selected element propositions have been rejected.")
        end
        redirect(resource(:element_propositions), :message => { :notice => message_text })
      else
        redirect(resource(:element_propositions), :message => { :error => _("Sorry, selected items haven't been found. They were accepted by another owner or topic has been removed.") })
      end
    end
  end

end
