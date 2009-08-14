jQuery.fn.extend((function() {
  return {
    blank: function() {
      return this.size() == 0;
    },

    url: function() {
      return this.attr('href') || this.attr('action');
    },

    focusFirstError : function() {
      this.find("input.error[type='text'], input.error[type='password'], input[type='text']").filter(":first").focus();
      return this;
    }
  };
})());