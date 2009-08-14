var Application = {
  init : function() {
    Application._setupAjax();
    Application._initLoginAndJoinLink();
    Application._initNewTopicLinks();
    Application._initNewElementLinks(); // FIXME move this call to favourites/topics/elements.js
    Application._initElementsComments(); // FIXME move this call to elements.js
    Application._initTopicsComments(); // FIXME move this call to topics.js
    Application._initFiltering();
    Application._initTagListAutoCompletion();
    ZeroClipboard.setMoviePath('/javascripts/lib/ZeroClipboard.swf');
    if (window._exec) {
      eval(window._exec);
    }
  },

  // Ajax

  _setupAjax : function() {
    $.ajaxSetup({
        error: function(xhr) {
          Message.errorFromXhr(xhr);
        }
    });
  },

  _showLoginForm: function() {
    var opts = {
      success: function(data) {
        var url = '' + window.location;
        window.location = url.replace(/_message=.+/, '').replace(/\?$/, '');
      },
      error: function(xhr, title, opts) {
        Modal.openModalWithContent(title, xhr.responseText, opts);
      }
    }
    Modal.openModalFromUrl(TRANSLATIONS['LOGIN'], '/login', opts);
  },

  // Login modal window

  _initLoginAndJoinLink : function() {
    $("#login_link").click(function() {
      Application._showLoginForm();
      return false;
    });

    $("#join_link").click(function() {
      Modal.openModalFromUrl(TRANSLATIONS['REGISTRATION'], this.href);
      return false;
    });
    $("#request_password").livequery('click', function() {
      Modal.openModalFromUrl(TRANSLATIONS['FORGOTTEN_PASSWORD'], this.href);
      return false;
    });
    $("#request_activation").livequery('click', function() {
      Modal.openModalFromUrl(TRANSLATIONS['REQUEST_ACTIVATION'], this.href);
      return false;
    });
    if (window._needAuth) {
      Application._showLoginForm();
    }
  },

  // New topic modal window

  openNewTopicForm: function() {
    Modal.openModalFromUrl(TRANSLATIONS['NEW_TOPIC'], '/topics/new', { width: 600 });
  },

  _initNewTopicLinks : function() {
    $(".new_topic_link").click(function() {
      Application.openNewTopicForm();
      return false;
    });
  },
  
  // New element modal window

  _initNewElementLinks : function() {
    $(".new_element_link").click(function() {
      Modal.openModalFromUrl(TRANSLATIONS['NEW_ELEMENT'], this.href, { width: 600 });
      return false;
    });
  },

  // Topic/element form language switching

  initContentChangeListener : function() {
    $("form.editing #topic_name, form.editing #topic_description, form.editing .element_name, form.editing .element_description").livequery('change', function() {
      CONTENT_CHANGED = true;
    });
  },

  initLanguageSwitcher : function() {
    $("form.editing .language_select").livequery(function() {
      var initialLanguage = $(this).val();
      CONTENT_CHANGED = false;
      $(this).change(function() {
        if (CONTENT_CHANGED && !confirm(TRANSLATIONS['CONFIRM_LANGUAGE_SWITCH'])) {
          $(".language_select").val(initialLanguage);
          return;
        }
        CONTENT_CHANGED = false;
        initialLanguage = $(this).val();
        var lang = $(this).val();
        $.getJSON(this.form.action + '/edit', function(entity) {
          $("#topic_name, .element_name").val(entity.name[lang] || '');
          $("#topic_description, .element_description").val(entity.description[lang] || '');
        });
      });
    });
  },

  // Topic/element comments

  _initElementsComments : function(){
    $("#element_comments .paginated a").click(function () {
      $("div#element_comments").load(this.href, function() {
        Application._initElementsComments();
      });
      return false;
    });
  },
  
  _initTopicsComments : function(){
    $("#topic_comments .paginated a").click(function () {
      $("div#topic_comments").load(this.href, function() {
        Application._initTopicsComments();
      });
      return false;
    });
  },

  // topic search boxes

  _initFiltering : function() {
    // handle search button
    $("#search .main-search").click(function() {
      $("form#search").submit();
      return false;
    });

    // autocomplete for topic search on homepage
    $("#search_terms").autocomplete('/search/tags_autocomplete', { delay: 200, matchSubset: false }).result(function (ev, item) { $("#search").submit() });

    // autofocus main search box
    $("#search_terms").focus();

    if (window.topAutocompleteUrl) {
      var params = Application._tagsToParams(Application._getSelectedTags());
      if (topAutocompleteUrl.indexOf('?') > -1) {
        var url = topAutocompleteUrl + '&';
      } else {
        var url = topAutocompleteUrl + '?';
      }
      $("#search #filter").autocomplete(url + params, { delay: 200, matchSubset: false }).result(function (ev, item) { Application._addTag(item); });
      $("#search #filter").focus();

      // handle filter button
      $("#search .filter-button").click(function() {
        Application._addTag($("#search #filter").val());
        return false;
      });
    } else {
      // disable filtering
      $("#search #filter").attr("readonly", "readonly");
      $("#search .filter-button").click(function() { return false });
    }


    // adding tags from tag cloud
    $(".tag-cloud a").click(function() {
      Application._addTag($(this).html());
      return false;
    });

    // removing selected tag
    $(".selected_tags a").click(function() {
      Application._removeTag($(this).html());
      return false;
    });

    $(".filter_form").submit(function() {
      Application._addTag($("#search #filter").val());
      return false;
    });
  },

  _addTag : function(tag) {
    var newTags = Application._getSelectedTags().concat([tag]);
    Application._reloadResults(newTags);
  },

  _removeTag : function(tag) {
    var newTags = Application._getSelectedTags();
    newTags.remove(tag);
    Application._reloadResults(newTags);
  },

  _getSelectedTags : function() {
    var tagNames = []
    $(".selected_tags a").each(function(i, tag) {
      tagNames[i] = $(tag).html();
    });
    return tagNames;
  },

  _tagsToParams : function(tags) {
    var params = [];
    for (var i=0; i<tags.length; i++) {
      params[i] = 'tags[]=' + tags[i];
    }
    return params.join('&');
  },

  _reloadResults : function(tags) {
    var url = ('' + window.location);
    var endPos = url.indexOf('?');
    var baseUrl = endPos > -1 ? url.substring(0, endPos) : url;
    var params = Application._tagsToParams(tags);
    window.location = baseUrl + (params.length > 0 ? '?' + params : "");
  },

  _initTagListAutoCompletion : function() {
    $("input[type='text'][name*='[tag_list]']").livequery(function() {
      $(this).autocomplete('/search/all_tags', { delay: 200, matchSubset: false, multiple: true });
    });
  },

  initPermalinks : function() {
    $("#permalink_link").click(function() {
      Modal.openModalFromUrl(TRANSLATIONS['PERMALINK'], this.href, { width: 600, onShow: Application._initCopyButton });
      return false;
    });
  },

  _initCopyButton : function() {
      var clip = new ZeroClipboard.Client();
      clip.setText($('input#permalink').val());
      clip.setHandCursor(true);
      clip.setCSSEffects(true);
      clip.addEventListener( 'mouseOver', function(client) {
        $(client).addClass("hover")
      } );
      clip.addEventListener( 'mouseOut', function(client) {
        $(client).removeClass("hover")
      } );
      clip.glue('copy_permalink');
      return false;
  },

  initOwnersGravatarsSlideshow : function() {
    $('.owners').cycle({ fx: 'fade', speed: 1500, timeout:  5000 });
  }
  
};

if (!Array.indexOf) {
  Array.prototype.indexOf = function(obj) {
    for(var i=0; i<this.length; i++) {
      if(this[i]==obj) {
        return i;
      }
    }
    return -1;
  }
}

Array.prototype.remove=function(s){
  var i = this.indexOf(s);
  if(i != -1) this.splice(i, 1);
}

$(Application.init);
