$ ->

  $('[data-toggle="tooltip"]').tooltip()

  $("body").on "replaced", (event) ->
    $('[data-toggle="tooltip"]').tooltip()


