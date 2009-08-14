var Friends = {
  init : function() {
    Friends._initRemoveLinks();
    Friends._initInviteFriend();
  },

  _initRemoveLinks : function() {
    $("a.remove_friend").click(function() {
      return confirm(TRANSLATIONS['CONFIRM_FRIEND_REMOVAL']);
    });
    
    $("a.remove_pending").click(function() {
      return confirm(TRANSLATIONS['CONFIRM_PENDING_FRIEND_REMOVAL']);
    });
    
    $("a.remove_requested").click(function() {
      return confirm(TRANSLATIONS['CONFIRM_REQUESTED_FRIEND_REMOVAL']);
    });
    
    $("a.cancel").click(function() {
      return confirm(TRANSLATIONS['CONFIRM_EMIAL_INVITE_CANCEL']);
    });
    
  },
  
  _initInviteFriend : function(){
    $("a#invite_friend").click(function(){
      Modal.openModalFromUrl(TRANSLATIONS['INVITE_FRIEND'], this.href);
      return false; 
    });
  }

}

$(Friends.init);