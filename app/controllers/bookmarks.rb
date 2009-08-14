class Bookmarks < Application
  before :ensure_authenticated
  before :ensure_owner, :exclude => [:new, :create, :index, :tags_autocomplete, :complete_adding]
  before :load_language, :only => [:new]
  before :sanitize_keywords, :only => :tags_autocomplete

  provides :json, :xml

  def index(tags = [])
    valid_tags = Tag.all(:name => tags)
    @selected_tags = valid_tags.map { |tag| tag.name }
    @page_count, @bookmarks = Bookmark.search(valid_tags, :user => session.user, :per_page => session.user.search_results_per_page, :page => pagination_page)
    @all_tags = Tag.search_in_bookmarks(valid_tags, session.user, :limit => 50)
    # :conditions => ['role = ? or role = ?', role_index, 2role_index]
    @user_topics = session.user.editable_topics.all.sort_by { |et| translate(et.name).downcase }
    display(@bookmarks)
  end
  
  def show
    display(@bookmark)
  end
  
  def new
    lang = @language.iso_code
    only_provides :html 
    element = Element.get(params[:element_id])
    if element
      if element.viewable_by?(session.user)
        @bookmark = Bookmark.new(:name => translate(element.name), :url => element.url, :tag_list => element.tag_list.join(","), :description => translate(element.description)) 
      else
        raise Forbidden
      end
    else
      @bookmark = Bookmark.new 
    end
    request.xhr? ? partial(:new_bookmark) : render
  end
  
  def create
    @bookmark = session.user.bookmarks.new(params[:bookmark])
    if @bookmark.save
      if request.xhr?
        return ""
      elsif content_type == :html
        redirect url(:bookmarks) , :message => { :notice => _( "Bookmark added" ) }
      else
        render "", :status => 201, :layout => false
      end
    else
      if request.xhr?
        partial(:new_bookmark)
      elsif content_type == :html
        render :new
      else
        display(@bookmark, :new, :status => 400)
      end
    end
  end
  
  def edit
    only_provides :html
    request.xhr? ? partial(:edit_bookmark) : render
  end
  
  def update
    if @bookmark && @bookmark.update_attributes(params[:bookmark])
      if content_type == :html && !request.xhr?
        redirect url(:bookmarks), :message => { :notice => _( "Bookmark updated" ) } 
      else
        render "", :layout => false
      end
    else
      if request.xhr?
        partial(:edit_bookmark)
      else
        display(@bookmark, :edit, :status => 400)
      end
    end
  end
  
  def delete
    @bookmark.destroy
    if content_type == :html
      redirect url(:bookmarks)
    else
      render "", :layout => false, :status => 201
    end
  end
  
  def tags_autocomplete(q, limit=10, tags=[])
    BookmarkTagSearch.new(q, limit, tags, session.user).find
  end

  protected
  
  def ensure_owner
    @bookmark = session.user.bookmarks.get(params[:id])
    raise Forbidden unless @bookmark
  end
  
  def load_language
    @language = Language[params[:lang]] || session.user.primary_language || Language[self.language_from_headers] || Language[Cayox::CONFIG[:fallback_language_code]]
  end
  
end
