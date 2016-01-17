$ ->

  if $('body').attr('data-autoscroll')?

    logger= Logger.create namespace: 'Scroller', level: 'warn'

    autoscrolling= false

    do ->
      throttle= (type, name) ->
        running= false
        func= ->
          unless autoscrolling
            unless running
              running = true
              requestAnimationFrame ->
                window.dispatchEvent new CustomEvent(name)
                running = false
        window.addEventListener type, func
      throttle 'scroll', 'user-scrolling'

    window.addEventListener 'user-scrolling', ->
      logger.debug "USER is scrolling"
      if !!window.location.hash
        window.location.hash= '#no-target'

    rescroll= ()->
      if !!window.location.hash
        autoscrolling= true
        logger.debug ["PRE SCROLL ", {autoscrolling: autoscrolling}]
        if $(window.location.hash).length
          y = if window.location.hash.match(/_bottom/)
                $(window.location.hash).offset().top - $(window).height() + 50
              else
                $(window.location.hash).offset().top
          $.scrollTo({left: 0, top: y}, 100,
            onAfter: (e)->
              setTimeout( ->
                autoscrolling= false
                logger.debug ["POST SCROLL ", {autoscrolling: autoscrolling}]
              500))

    rescroll()

    $("body").on "after:replace-elements", (e)->
      rescroll()

    $(window).on "hashchange", (e)->
      rescroll()


