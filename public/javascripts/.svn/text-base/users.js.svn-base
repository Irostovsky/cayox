var Users = {
  init : function() {
    // handler for toggling password fields
    $("#change_password").click(function() { $("#password_fields").toggle(); return false });

    // handler for adding another secondary language
    $("#add_language").click(function() {
      var currentParagraph = $(this).parent();
      var templateParagraph = $("#language_combo_template");
      var newParagraph = templateParagraph.clone(true);
      newParagraph.insertBefore(currentParagraph);
      newParagraph.show();
      return false;
    });

    // handler for removing secondary language
    $(".remove_language").click(function() {
      $(this).parent().remove();
      return false;
    });

    $("#edit_user_form").focusFirstError();
    
    
    $("a#promote").click(function() {
      return confirm(TRANSLATIONS['PROMOTE_TO_ADMIN']);
    });
  }
}

$(Users.init);