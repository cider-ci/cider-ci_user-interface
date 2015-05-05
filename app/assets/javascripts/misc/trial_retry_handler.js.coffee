#  Copyright (C) 2013, 2014, 2015 Dr. Thomas Schank  (DrTom@schank.ch, Thomas.Schank@algocon.ch)
#  Licensed under the terms of the GNU Affero General Public License v3.
#  See the LICENSE.txt file provided with this software.

# takes care of the retry button in a task row shown in the job page
# * disable button before sending request, i.e. right away
# * submit the row for immediate reloading on complete (either success of failure)
# * have the summary be scheduled for reloading 

$ -> 

  $(document).on "ajax:beforeSend", (e)->
    $target = $(e.target)
    if $target.hasClass("retry-tasks")
      $target.removeAttr("data-remote")
      $button = $target.find("button")
      $button.html("sending ...")
      $button.addClass("disabled")
      $target.removeClass("btn-primary")
      Reloader.abortCurrent()

  $(document).on "ajax:success", (e)->
    $target = $(e.target)
    if $target.hasClass("retry-tasks")
      $button= $target.find("button")
      $button.addClass("btn-success")
      $button.html("retrying")
      Reloader.reloadAsap()
