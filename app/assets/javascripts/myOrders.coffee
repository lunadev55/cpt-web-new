//= require shared

$ ->
    $("li[data-myorders]").click (view) ->
        call_new_screen(this,view)
        #$.get('/exchange/open_orders/')
        
        #if confirm "Esta é uma ação destrutiva. Prosseguir?"
        # if answer yes
            
        #else
        # if answer no
        