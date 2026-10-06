document.addEventListener('DOMContentLoaded', function () {
  var form = document.querySelector('form');
  if (form) {
    form.addEventListener('submit', function (event) {
      var email = form.querySelector('input[name="email"]');
      if (email && !email.value.trim()) {
        event.preventDefault();
        email.focus();
      }
    });
  }
});
