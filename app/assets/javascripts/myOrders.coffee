//= require shared

$ ->
    $("li[data-myorders]").click (view) ->
        if confirm "Esta é uma ação destrutiva. Prosseguir?"
        # if answer yes
            call_new_screen(this,view)
        else
        # if answer no
        