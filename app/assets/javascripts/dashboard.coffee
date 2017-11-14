# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
    $("a[data-painel-menu]").click (view) ->
        view.preventDefault()
        option = $(this).data("painel-menu")
        if option is "overview"
            get_ajax(option,'payments_details')
        else if option is "deposit"
            get_ajax(option,'/dashboard/info/getwallets')
        else
            get_ajax(option,'')
            
$ ->
    $.get('payments_details')

get_ajax = (route,callbackroute) -> 
    if callbackroute is ''
        $.ajax 'layouts/'+route,
                type: 'GET'
    else
        $.ajax 'layouts/'+route,
                type: 'GET'
                error: (jqXHR, textStatus, errorThrown) ->
                    $('body').append "AJAX Error: #{textStatus}"
                success: (data, textStatus, jqXHR) ->
                    $.ajax callbackroute, 
                        type: 'GET' 