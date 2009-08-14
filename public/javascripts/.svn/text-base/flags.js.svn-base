var Flags = {
  init: function() {
    Flags._initFlaggedForms();
  },

   _initFlaggedForms: function() {
     $(".flagged_form").submit(function() {
       if ($(this).find("input[type='checkbox']:checked").length == 0) {
         alert(TRANSLATIONS['SELECT_ITEMS']);
         return false;
       }
     });

     $("td a.flagged").click(function() {
       $(this).nextAll("p").toggle();
       return false;
     });
   }
   
};

$(Flags.init);
