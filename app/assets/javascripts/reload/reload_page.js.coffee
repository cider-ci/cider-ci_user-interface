$ ->

  reloadEnabled= true

  logger= Logger.create namespace: 'Reloader', level: 'warn'

  reloadTimeout= $("#reload-page").data('reload-timeout') ? 5

  logger.debug reloadTimeout: reloadTimeout

  $("#reload-page").attr({'data-reloaded-at': moment().format()}) 


  setReplaceLock= ->
    $("#reload-page").attr({'data-not-replace-before': moment().add("seconds",3)})

  $(document).on "click", "form", ()-> setReplaceLock()
  $(document).on "change", "form", ()->setReplaceLock()

  checkIsAfterReplaceLock= ->
    unless $("#reload-page").attr("data-not-replace-before")?
      true
    else
      moment().isAfter($("#reload-page").attr("data-not-replace-before"))


  replaceAnimated= ($old,$new)->
    logger.debug "replacing animated"
    $old.fadeOut "slow", ->
      $new.hide()
      $(this).replaceWith($new)
      $new.fadeIn("slow")
      # TODO when does it get replaced?
      $new.trigger("replaced")
      $("#reload-page").attr({'data-reloaded-at': moment().format()}) 

  replacePageWith= (data)->
    if checkIsAfterReplaceLock()
      $new= $("#reload-page",data)
      if not $("#reload-page").data("cache-tag")? 
        logger.debug "replacing without animation"
        $('#reload-page').replaceWith($new)
        $("#reload-page").attr({'data-reloaded-at': moment().format()}) 
        $new.trigger("replaced")
      else if $("#reload-page").data("cache-tag") isnt $new.data("cache-tag") 
        # something has changed, replace visually
        replaceAnimated $('#reload-page'), $new 
      else
        logger.debug "no change, no replacing"



  reload= -> 

    reloadId= Math.random()
    $("#reload-page").attr("data-reload-id",reloadId)
    $.ajax
      url: window.location.href
      dataType: 'html'
      success: (data)->
        if $("#reload-page").attr("data-reload-id") == reloadId.toString()
          replacePageWithReactMagic(data) # <- where the magic happens :)
      complete: ()->
          $("#reload-page").removeAttr("data-reload-id")

  do reloadLoop= ->

    logger.debug "reloadLoop"

    reloadedAt= moment($("#reload-page").data('reloaded-at'))

    isAfterTimeout= moment().isAfter(reloadedAt.add('seconds',reloadTimeout))
    doesNotHaveReloadId= not $("#reload-page").attr("data-reload-id")?
    isAfterReplaceLock= checkIsAfterReplaceLock()

    logger.debug({
      isAfterTimeout: isAfterTimeout,
      doesNotHaveReloadId: doesNotHaveReloadId,
      isAfterReplaceLock: isAfterReplaceLock })

    if reloadEnabled and isAfterTimeout and isAfterReplaceLock and doesNotHaveReloadId
      reload()

    setTimeout reloadLoop, 1000


  #### React magic #############################################################

  #
  # some code borrowed from
  # <https://github.com/reactjs/react-magic/blob/gh-pages/magic.js>
  converter= new HTMLtoJSX({createClass: false})
  container= '#reload-page'

  replacePageWithReactMagic= (data)->
    if checkIsAfterReplaceLock()
      newHTML = $(data).find(container).html()
      reactRender(newHTML)

  reactRender= (html)->
    processed= reactComponentFromHTML(html)
    React.renderComponent(processed, $(container)[0])

  reactComponentFromHTML= (html)->
    jsx = '/** @jsx React.DOM */ ' + converter.convert(html)
    try
      return JSXTransformer.exec(jsx)
    catch error
      throw new Error('Error transforming HTML to JSX: ' + error)
      console.log(jsx)
      do window.location.reload

  do initReactMagic= ->
    initialHTML = $(container).html()
    # Re-render existing content using React, so state transitions work
    # correctly.
    reactRender(initialHTML)

  #### /React magic ############################################################


  window.Reloader={}
  window.Reloader.disable= ->
    reloadEnabled= false

