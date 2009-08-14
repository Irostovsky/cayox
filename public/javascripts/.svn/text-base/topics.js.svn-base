var Topics = {
  init : function() {
    Topics._initEditLinks();
    Topics._initFlagLink();
    Topics._initAddToFavsLinks();
    Topics._initAverageVotes();
    Topics._initAbandonLinks();
    Application.initContentChangeListener();
    Application.initLanguageSwitcher();
    Application.initPermalinks();
    Application.initOwnersGravatarsSlideshow();
  },

  _initEditLinks : function() {
    $(".edit_topic_link").click(function() {
      Modal.openModalFromUrl(TRANSLATIONS['EDIT_TOPIC'], this.href, { width: 600 });
      return false;
    });
  },

  _initAddToFavsLinks : function(elem) {
    $("a.add_to_favs_link").click(function() {
      $("#add_to_favs_form").submit();
      return false;
    });
  },
  
  _initAverageVotes : function() {
    $("#vote_form input[type='radio']").each(function() { if ($(this).attr("_checked")) $(this).attr("checked", true) }); // workaround for FF bug: https://bugzilla.mozilla.org/show_bug.cgi?id=394782
    $('input.vote_star').rating({ 
      callback: function(value, link){
        $.ajax({
          url : "/voting/topic_vote",
          data : $("form").serialize(),
          type : "POST"
        });
      } 
    }); 
  },
  
  _initAbandonLinks : function(){
    $("a.abandon").click(function() {
      return confirm(TRANSLATIONS['ABANDON_TOPIC']);
    });
    $("a.remove_topic").click(function() {
      return confirm(TRANSLATIONS['REMOVE_TOPIC']);
    });
  },
  
  // Topic flagging

  _initFlagLink : function() {
    $(".flag_topic_link").click(function() {
      Modal.openModalFromUrl(TRANSLATIONS['FLAG_TOPIC'], this.href, { width: 400, onShow: function() { Recaptcha.create($("#recaptcha_public_key").val(), document.getElementById("recaptcha"), { theme: "white" }) } });
      return false;
    });
  }

};

$(Topics.init);
