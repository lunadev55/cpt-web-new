(function() {
  this.call_new_screen = function(object, view) {
    var option;
    view.preventDefault();
    $(".loading_menu").remove();
    $(".active").removeClass("active");
    $(object).addClass("active");
    option = $(object).data("painel-menu");
    if (option === void 0) {
      option = $(object).data("myOrders-menu");
    } else {
      $(object).append('<i class="fa fa-spinner fa-pulse fa-fw loading_menu"></i>');
    }
    if (option === "deposit") {
      return get_ajax(option, '/dashboard/info/getwallets');
    } else {
      return get_ajax(option, '');
    }
  };

  this.executeQuery = function() {
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
          $('.LTC_BCH_buy').html(data["LTC/BCH_buy"]);
          $('.LTC_BCH_sell').html(data["LTC/BCH_sell"]);
          $('.BCH_BTC_buy').html(data["BCH/BTC_buy"]);
          $('.BCH_BTC_sell').html(data["BCH/BTC_sell"]);
          $('.ETH_BTC_buy').html(data["ETH/BTC_buy"]);
          $('.ETH_BTC_sell').html(data["ETH/BTC_sell"]);
          $('.DOGE_BTC_buy').html(data["DOGE/BTC_buy"]);
          $('.DOGE_BTC_sell').html(data["DOGE/BTC_sell"]);
          $('.ETH_LTC_buy').html(data["ETH/LTC_buy"]);
          $('.ETH_LTC_sell').html(data["ETH/LTC_sell"]);
          $('.BCH_ETH_buy').html(data["BCH/ETH_buy"]);
          $('.BCH_ETH_sell').html(data["BCH/ETH_sell"]);
          $('.DASH_BTC_buy').html(data["DASH/BTC_buy"]);
          $('.DASH_BTC_sell').html(data["DASH/BTC_sell"]);
          $('.DASH_LTC_buy').html(data["DASH/LTC_buy"]);
          $('.DASH_LTC_sell').html(data["DASH/LTC_sell"]);
          $('.DGB_BTC_buy').html(data["DGB/BTC_buy"]);
          $('.DGB_BTC_sell').html(data["DGB/BTC_sell"]);
          $('.DGB_DOGE_buy').html(data["DGB/DOGE_buy"]);
          $('.DGB_DOGE_sell').html(data["DGB/DOGE_sell"]);
          $('.ZEC_BTC_buy').html(data["ZEC/BTC_buy"]);
          $('.ZEC_BTC_sell').html(data["ZEC/BTC_sell"]);
          $('.ZEC_ETH_buy').html(data["ZEC/ETH_buy"]);
          return $('.ZEC_ETH_sell').html(data["ZEC/ETH_sell"]);
        }
      });
    }
  };

  this.post_ajax = function(route) {
    return $.ajax(route, {
      type: 'POST'
    });
  };

  this.get_ajax = function(route, callbackroute) {
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
(function() {
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
      return call_new_screen(this, view);
    });
  });

}).call(this);
