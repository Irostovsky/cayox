var Elements = {
  init : function() {
    Elements._initRemoveElementLinks();
    Elements._initEditLinks();
    Elements._initFlagLink();
    Elements._initStarBasedVotingForm();
    Elements._initBookmarkModal();
    Elements._initProposedElementsForm();
    Application.initContentChangeListener();
    Application.initLanguageSwitcher();
    Application.initPermalinks();
  },

  _initStarBasedVotingForm : function() {
    $("#vote_form input[type='radio']").each(function() { if ($(this).attr("_checked")) $(this).attr("checked", true) }) // workaround for FF bug: https://bugzilla.mozilla.org/show_bug.cgi?id=394782
    $('input.vote_star').rating({ 
      callback: function(value, link){
        $.ajax({
          url : "/voting/create",
          data : $("form").serialize() ,
          type : "POST"
        });
      } 
    }); 
  },

  _initRemoveElementLinks : function(elem) {
    $("a.remove_element").click(function() {
      if (confirm(TRANSLATIONS['CONFIRM_ELEMENT_REMOVAL'])) {
        $("#remove_element_form").submit();
      }
      return false;
    });
  },

  // Element editing modal window

  _initEditLinks : function() {
    $(".edit_element_link").click(function() {
      Modal.openModalFromUrl(TRANSLATIONS['EDIT_ELEMENT'], this.href, { width: 600 });
      return false;
    });
  },

  // Element flagging

  _initFlagLink : function() {
    $(".flag_element_link").click(function() {
      Modal.openModalFromUrl(TRANSLATIONS['FLAG_ELEMENT'], this.href, { width: 400, onShow: function() { Recaptcha.create($("#recaptcha_public_key").val(), document.getElementById("recaptcha"), { theme: "white" }) } });
      return false;
    });
  },

  // bookamrking modal
  _initBookmarkModal : function() {
    $(".add_bookmark_link").click(function() {
      Modal.openModalFromUrl(TRANSLATIONS['ADD_BOOKMARK'], this.href);
        return false;
      });
   },

   _initProposedElementsForm: function() {
     $("#proposed_elements_form").submit(function() {
       if ($(this).find("input[type='checkbox']:checked").length == 0) {
         alert(TRANSLATIONS['SELECT_ELEMENTS']);
         return false;
       }
     });
   }
   
};

$(Elements.init);
