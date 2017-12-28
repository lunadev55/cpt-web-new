(function() {
  var executeQuery, get_ajax;

  $(function() {
    return $("tr[data-payment-detail]").click(function(view) {
      var option;
      view.preventDefault();
      option = $(this).data("payment-detail");
      return get_ajax(option, '/dashboard/info/getpayment/');
    });
  });

  $(function() {
    return $("a[data-painel-menu]").click(function(view) {
      var option;
      view.preventDefault();
      option = $(this).data("painel-menu");
      if (option === "overview") {
        return get_ajax(option, 'payments_details');
      } else if (option === "deposit") {
        return get_ajax(option, '/dashboard/info/getwallets');
      } else {
        return get_ajax(option, '');
      }
    });
  });

  executeQuery = function() {
    if ($(".current_place").prop("place") !== "overview") {
      return $.get('/exchange/open_orders');
    } else {
      return $.ajax('/exchange/open_orders', {
        type: 'GET',
        dataType: "json",
        error: function(jqXHR, textStatus, errorThrown) {
          return console.log("AJAX Error: " + textStatus);
        },
        success: function(data, textStatus, jqXHR) {
          $('.LTC_BTC_buy').html(data["LTC/BTC_buy"]);
          $('.LTC_BTC_sell').html(data["LTC/BTC_sell"]);
          $('.ETH_BTC_buy').html(data["ETH/BTC_buy"]);
          $('.ETH_BTC_sell').html(data["ETH/BTC_sell"]);
          $('.DOGE_BTC_buy').html(data["DOGE/BTC_buy"]);
          $('.DOGE_BTC_sell').html(data["DOGE/BTC_sell"]);
          $('.ETH_LTC_buy').html(data["ETH/LTC_buy"]);
          $('.ETH_LTC_sell').html(data["ETH/LTC_sell"]);
          $('.BCH_BTC_buy').html(data["BCH/BTC_buy"]);
          $('.BCH_BTC_sell').html(data["BCH/BTC_sell"]);
          $('.DASH_BTC_buy').html(data["DASH/BTC_buy"]);
          return $('.DASH_BTC_sell').html(data["DASH/BTC_sell"]);
        }
      });
    }
  };

  $(function() {
    return $.get('payments_details');
  });

  get_ajax = function(route, callbackroute) {
    if (callbackroute === '') {
      return $.ajax('layouts/' + route, {
        type: 'GET'
      });
    } else {
      return $.ajax('layouts/' + route, {
        type: 'GET',
        error: function(jqXHR, textStatus, errorThrown) {
          return $('body').append("AJAX Error: " + textStatus);
        },
        success: function(data, textStatus, jqXHR) {
          return $.ajax(callbackroute, {
            type: 'GET'
          });
        }
      });
    }
  };

}).call(this);
