var Bookmarks = {
  init : function() {
    Bookmarks._initCreateTopicFromBookmarks();
    Bookmarks._initRemoveLinks();
    Bookmarks._initAddElementsToTopicFromBookmarks();
    Bookmarks._initCreateNewBookmark();
    Bookmarks. _initEditBookmark();
  },

  _initCreateTopicFromBookmarks : function() {
     $("#create_topic_from_bookmarks_link").click(function() {
      var bookmarks = $("#create_topic_from_bookmarks").serializeArray();
      var bookmarks = $.map(bookmarks, function(n, i){ return n.value; }  );
      var bookmarks = bookmarks.join(",");
      Modal.openModalFromUrl(TRANSLATIONS['NEW_TOPIC'], "/topics/new?bookmarks=" + bookmarks);
      return false;
    });
  },

  _initAddElementsToTopicFromBookmarks : function() {
     $("#add_bookmarks_to_topic").submit(function() {
      var bookmarks = $("#create_topic_from_bookmarks").serializeArray();
      var bookmarks = $.map(bookmarks, function(n, i){ return n.value; }  );
      var bookmarks = bookmarks.join(",");
      this.action += "?bookmarks=" + bookmarks ;
      return true;
    });
  },


  _initRemoveLinks : function() {
    $("a.remove_bookmark").click(function() {
      return confirm(TRANSLATIONS['CONFIRM_BOOKMARK_REMOVAL']);
    });
  },
  
  _initCreateNewBookmark : function() {
    $("#create_new_bookmark_link").click(function(){
      Modal.openModalFromUrl(TRANSLATIONS['ADD_BOOKMARK'], this.href, { width: 600 });
      return false;
    });
  },
  
  _initEditBookmark : function(){
    $(".edit_bookmark").click(function(){
      Modal.openModalFromUrl(TRANSLATIONS['EDIT_BOOKMARK'], this.href, { width: 600 });
      return false; 
    });
  }
  
};

$(Bookmarks.init);