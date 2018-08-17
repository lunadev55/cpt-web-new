(function() {
  $(function() {
    return $(".api-method").click(function(view) {
      var alert_message, route;
      route = $(this).data("api-route");
      alert_message = $(this).data("api-alert");
      if (confirm(alert_message)) {
        post_ajax(route);
        if (route === "/api/newKey") {
          console.log("newKey");
          $(".api-secret-key-modal").modal('show');
          return $(".apiChaves").html('<i class="fa fa-circle-o-notch fa-spin fa-5x fa-fw"></i>');
        }
      } else {

      }
    });
  });

}).call(this);
