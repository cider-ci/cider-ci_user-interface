$ ->

  logger= Logger.create namespace: 'Scroller', level: 'info'

  rescroll= ()->
    if !!window.location.hash
      y = if window.location.hash.match(/_bottom/)
            $(window.location.hash).offset().top - $(window).height() + 50
          else
            $(window.location.hash).offset().top
      logger.debug ["SCROLLING", {y: y}]
      setTimeout( scrollTo(0,y), 100)

  rescroll()

  $("body").on "after:replace-elements", (e)->
    rescroll()

  $(window).on "hashchange", (e)->
    rescroll()


