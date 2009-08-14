var Favourites = {
  init : function() {
    Favourites._initEditLinks();
    Favourites._initRemoveLinks();
    Favourites._initAverageVotes();
    Favourites._initFreshElementsForm();
    Application.initOwnersGravatarsSlideshow();
  },

  _initEditLinks : function() {
    $(".edit_favourite_link").click(function() {
      Modal.openModalFromUrl(TRANSLATIONS['EDIT_FAVOURITE'], this.href, { width: 600 });
      return false;
    });
  },

  _initRemoveLinks : function(elem) {
    $("a.remove_favourite").click(function() {
      if (confirm(TRANSLATIONS['CONFIRM_FAVOURITE_REMOVAL'])) {
        $("#remove_favourite_form").submit();
      }
      return false;
    });
  },

  _initAverageVotes : function() {
     $('input.vote_star').rating();
  },

   _initFreshElementsForm: function() {
     $("#fresh_elements_form").submit(function() {
       if ($(this).find("input[type='checkbox']:checked").length == 0) {
         alert(TRANSLATIONS['SELECT_ELEMENTS']);
         return false;
       }
     });

     $("td a.fresh").click(function() {
       $(this).nextAll("p").toggle();
       return false;
     });

   }
}

$(Favourites.init);
