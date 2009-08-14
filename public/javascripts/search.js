var Search = {
  init : function() {
    Search._initClosedUserGroupJoinModal();
  },
  
  
  _initClosedUserGroupJoinModal : function(){
    $("a.closed_topic").click( function() {
    Modal.openModalFromUrl(TRANSLATIONS['JOIN_CLOSED_USER_GROUP'],this.href); 
    return false;
    });
  }
  
};

$(Search.init);