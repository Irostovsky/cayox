var ElementPropositions = {
  init: function() {
    ElementPropositions._initProposedElementsForm();
  },

   _initProposedElementsForm: function() {
     $("#proposed_elements_form").submit(function() {
       if ($(this).find("input[type='checkbox']:checked").length == 0) {
         alert(TRANSLATIONS['SELECT_ELEMENTS']);
         return false;
       }
     });

     $("td a.proposed").click(function() {
       $(this).nextAll("p").toggle();
       return false;
     });
   }
   
};

$(ElementPropositions.init);
