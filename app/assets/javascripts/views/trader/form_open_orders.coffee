//= require shared
$ -> 
    $("li[data-order_form-options]").click (view) ->
        view.preventDefault()
        option = $(this).data("order_form-options")
        $(".active").removeClass("active")
        $(this).addClass("active")
        get_specific('/trader/'+option)
        