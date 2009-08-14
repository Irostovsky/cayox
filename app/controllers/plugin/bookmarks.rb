module Plugin
  class Bookmarks < Application
    layout 'plugin'

    def index
      @all_bookmarks = Bookmark.all
      render
    end

  end
end
