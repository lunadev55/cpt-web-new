# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
    $(".api-method").click (view) ->
        route = $(this).data("api-route")
        alert_message = $(this).data("api-alert")
        if confirm alert_message
            post_ajax(route)
            if route is "/api/newKey"
                console.log("newKey")
                $(".api-secret-key-modal").modal('show')
                $(".apiChaves").html('<i class="fa fa-circle-o-notch fa-spin fa-5x fa-fw"></i>')
        else
        # if answer no
        
        