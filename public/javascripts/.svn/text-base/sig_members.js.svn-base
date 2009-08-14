var SigMembers = {
  init: function() {
    SigMembers._initUserCombo();
    SigMembers._initRemoveButtons();
  },

   _initUserCombo: function() {
     $("#sig_member_user_id").change(function() {
       if ($(this).val() == -1) {
         $(this).next().show().focus();
       } else {
         $(this).next().hide();
       }
     });
   },
   
   _initRemoveButtons: function() {
     $(".remove_role").click(function() {
       var prevRow = $(this).parents("td").prev("td");
       prevRow.find("input[name='_method']").val("delete");
       prevRow.find("form").submit();
       return false;
     });
   }
};

$(SigMembers.init);
