var Notifications = {

  init : function() {
    Notifications._initDatePickers();
    Notifications._initResendButton();
  },

  _initDatePickers : function() {
    $(".datepicker").datepicker({
      dateFormat: 'yy-mm-dd',
      duration: "",
      showOn: "focus",
      buttonImageOnly: true
    });
  },

  _initResendButton : function() {
    $("#resend_button").click(function() {
      if ($("#notifications input[type='checkbox']:checked").length == 0) {
        alert(TRANSLATIONS['SELECT_NOTIFICATION']);
        return false;
      }
      return true;
    });
  }

}

$(Notifications.init);
