var Message = {

errorFromXhr : function(xhr) {
    if (xhr.status >= 400 && xhr.status < 500)
      Message.error(xhr.responseText);
    if(xhr.status >= 500)
      Message.error(TRANSLATIONS['UNKNOWN_ERROR']);
  },

  error : function(message) {
    //Application._showFlash("error", message);
    alert(message);
  }

}