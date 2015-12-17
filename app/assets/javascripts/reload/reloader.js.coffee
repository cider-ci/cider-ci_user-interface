$ ->

  #### Initialize ##############################################################

  logger= Logger.create namespace: 'Reloader', level: 'info'

  isReloadEnabled= true
  reloadTimeout= null  # define here, so it will not end up in a deeper closure

  $("#reload-page").attr({'data-reloaded-at': moment().format()})



  #### Reload timeout ##########################################################

  readReloadTimeout= ($el) ->
    $el ||= $("#reload-page")
    Math.max(1,
      Math.min(60,
        parseFloat($el.attr('data-reload-timeout')) || 10))

  setReloadTimeout= (reloadTimeout)->
    $("#reload-page").attr({'data-reload-timeout': reloadTimeout})


  #### Replace #################################################################

  replaceElement= ($old,$new,id)->
    logger.debug ["replacing animated",$old,$new,id]
    throw "can not replace" unless $old? and $new and id
    $old.replaceWith($new)
    $replaced= $("##{id}")
    unless $replaced.hasClass("replace-without-animation")
      if ($replaced.parents(".replace-without-animation").length == 0)
        $replaced.hide()
        $replaced.fadeIn(1000)
    $replaced.trigger("replaced")


  replacePageWith= (data)->

    $new= $("#reload-page",data)

    $("#reload-page").trigger("before:replace-elements")

    $(".reload").each (i,el)->
      try
        $el= $(el)
        id = $el.attr("id")
        $new_el = $new.find("##{id}")
        oldCacheTag= $el.attr("data-cache-signature")
        newCacheTag= $new_el.attr("data-cache-signature")
        if (not oldCacheTag) or (oldCacheTag isnt newCacheTag)
          replaceElement $el, $new_el, id
        $el.attr("data-cache-signature",newCacheTag)
      catch error
        logger.error error

    $("#reload-page").trigger("after:replace-elements")


    setReloadTimeout readReloadTimeout($new)
    $("#reload-page").attr({'data-reloaded-at': moment().format()})


  reload= ->

    reloadId= Math.random()
    $("#reload-page").attr("data-reload-id",reloadId)
    $.ajax
      url: window.location.href
      dataType: 'html'
      success: (data)->
        if $("#reload-page").attr("data-reload-id") == reloadId.toString()
          replacePageWith(data)
          $("#reload-page").attr({'data-reloaded-at': moment().format()})

      complete: ()->
        $("#reload-page").removeAttr("data-reload-id")


  do reloadLoop= ->
    reloadTimeout= readReloadTimeout()
    logger.debug "reloadLoop",{reloadTimeout: reloadTimeout}

    reloadedAt= $("#reload-page").attr('data-reloaded-at')
    reloadedAtMoment= moment(reloadedAt)

    isAfterTimeout= moment().isAfter(reloadedAtMoment.add('seconds',reloadTimeout))
    doesNotHaveReloadId= not $("#reload-page").attr("data-reload-id")?

    logger.debug({
      reloadedAt: reloadedAt,
      isReloadEnabled: isReloadEnabled,
      isAfterTimeout: isAfterTimeout,
      doesNotHaveReloadId: doesNotHaveReloadId })

    if isReloadEnabled and isAfterTimeout and doesNotHaveReloadId
      reload()

    setTimeout reloadLoop, 1000


  #### Some control ############################################################

  abortCurrent= ->
    logger.info "abort current"
    $("#reload-page").attr("data-reload-id",null)

  disable= ->
    logger.info "disable"
    isReloadEnabled= false

  reloadAsap= ->
    logger.info "reload asap"
    setReloadTimeout(1)

  #### Window ##################################################################

  window.Reloader={}
  window.Reloader.disable= disable
  window.Reloader.reloadAsap= reloadAsap
  window.Reloader.abortCurrent= abortCurrent

