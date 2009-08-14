var Modal = {

  modalContainer : '#nyroModalContent',

  openModalWithContent : function(title, content, opts) {
    opts = opts || {};
    var w = opts.width || 400;
    var html = '';
    html += '<div class="header">' + title + '<a class="close" href="#">Close</a>' + '</div>';
    html += '<div class="content">' + content + '</div>';
    $.nyroModalManual({ bgColor: '#000000', content: html, closeButton: '', closeSelector: '.close', 
                        endShowContent: function() { Modal._ajaxifyModalForm(title, opts); },
                        wrap: { manual: '<div class="wrapper" id="modal"></div>' },
                        minWidth: w, width: w , minHeight: 50 });
  },

  openModalFromUrl : function(title, url, opts) {
    $.ajax({
        url: url,
        error: function(xhr, textStatus) {
          if (xhr.status == 401) {
            Modal.openModalWithContent(title, xhr.responseText, opts);
          } else {
            Message.errorFromXhr(xhr);
          }
        },
        success: function(data) {
          Modal.openModalWithContent(title, data, opts);
        }
      });
  },

  _ajaxifyModalForm : function(title, opts) {
    var form = $("#modal form");
    opts = opts || {};
    form.focusFirstError();
    form.submit(function() {
      $(this).find("input[type='submit']").attr({ disabled: 'disabled' });
      $(this).find(".indented").append('<img src="/images/ajax-loader-small.gif" border="0" class="form_spinner" />');
      $.ajax({
          url: $(this).attr("action"),
          type: 'POST',
          data: $(this).serialize(),
          success:  function(data) {
            var redirect = data.match(/^(http:.+)?\/.*/) ? true : false;
            if (opts.success) {
              opts.success(data, redirect);
            } else {
              if (data == "") {
                Modal.closeModal();
                window.location = window.location;
              } else if (redirect) {
                window.location = data;
              } else if (!data.match(/\<html\>/)) {
                Modal.openModalWithContent(title, data, opts);
              }
            }
            if (opts.afterSuccess)
              opts.afterSuccess(data, redirect);
          },
          error : function(xhr, textStatus) {
            if (opts.error)
              opts.error(xhr, title, opts);
          }
        }
      );
      return false;
    });
    if (opts.onShow)
      opts.onShow();
  },

  closeModal : function() {
    $.nyroModalRemove();
  }

}
