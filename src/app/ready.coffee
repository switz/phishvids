app = require '../app'
config = require './config'
{ view, ready } = require './index'
{ jsonToSetlist, fixSegue, getShow, compareTitleToSetlist } = require '../lib/show_utils'
{ addZero } = require '../lib/utils'

#############
## Ready
#############

ready (model) ->
  month = model.at '_month'
  day = model.at '_day'
  year = model.at '_year'
  number = model.at '_number'
  newVideo = model.at '_newVideo'
  validateVideos = model.at '_validateVideos'
  scroll = model.at '_scroll'

  model.setNull '_years', config.YEAR_ARRAY

  @on 'render', (ctx) ->
    PhishVids()
    _gaq.push ['_trackPageview', window.location.pathname]

    scrollGet = scroll.get()

    for c of scrollGet
      $(".span3 ul.#{c}").scrollTop scrollGet[c]

    $('.span3 ul').scroll ->
      c = $(this).attr('class')
      scroll.set c, $(".span3 ul.#{c}").scrollTop()

  # TODO: Refactor add/update into one function
  @add = ->
    data = newVideo.get()?.replace(/[ \t]+/g,'')?.split('\n')

    $.ajax
      url: '/api/v1/video/youtube'
      type: 'POST'
      data:
        data: data
      # Successful POST
      success: (data) ->
        if (!data || data.err || $.isEmptyObject data) then return false
        shows = []
        i = 0
        data.map (d) ->
          getShow d, (err, show, json) ->
            if json and !json.error
              show.net = json
              setlist = []
              setlistObj = fixSegue compareTitleToSetlist(jsonToSetlist(json, {}), show.title)

              # Just a crappy hack to satisfy Derby templating
              for x of setlistObj
                if setlistObj.hasOwnProperty x
                  setlist.push
                    key : x,
                    value : setlistObj[x]
              show.net.setlistObj = setlistObj
              show.net.setlist = setlist
            else
              show.showDate =
                date: new Date '1/1/2012'
                month: 1
                day: 1
                year: 2012
            show.i = i++
            shows.push show
            if i is data.length
              $('.add-form-container').slideUp()
              model.set '_isFront', false
              model.del m for m in ['_month','_day','_number','_show','_song','_tiph','_year','_shows','_about','_validateVideos']
              validateVideos.set
                data: shows
                years: config.YEAR_ARRAY
                months: [1..12]
                days: [1..31]
      # Error
      error: (jqXHR, textStatus, errorThrown) ->
        model.set '_message',
          msg: jqXHR.responseText.err

  @confirm = (e, el, next) ->
    $el = $(el)
    showModel = model.at($el.parent().siblings('h3')[0])
    show = showModel.get()

    unless show.net then return false
    setlistObj = show.net.setlistObj
    songnames = {}
    for i of setlistObj
      setlistObj[i].map (song) ->
        if song.selected
          songnames[song.number] = song.title

    show.songnames = songnames
    $.ajax
      url: '/api/v1/video/add'
      type: 'POST'
      data:
        show: show
        adminKey: window.adminKey || ''
      success: (json) ->
        $el.parents('.validate-video').slideUp 600, ->
          $('.validate-video').show()
          showModel.remove()

          if validateVideos.get().data.length is 0
            validateVideos.del()

  @reject = (e, el, next) ->
    $el = $(el)
    s = model.at($el.parent().siblings('h3')[0])

    $el.parents('.validate-video').slideUp 600, ->
      $('.validate-video').show()
      s.remove()
  @update = (e, el, next) ->
    $el = $(el)
    s = model.at($el.parent().siblings('h3')[0])
    show = s.get()
    name = $el.attr 'name'
    selected = +$el.find(':selected').val()

    unless show.hasOwnProperty 'showDate'
      show.showDate =
        month: 1
        day: 1
        year: 2012 # current year - don't trust client system
    show.showDate[name] = selected
    getShow show, (err, show, json) ->
      if err
        show.net = {}
      else
        show.net = json
        setlist = []
        setlistObj = fixSegue compareTitleToSetlist(jsonToSetlist(json, {}), show.title)
        # Just a crappy hack to satisfy Derby templating
        # Converts object to array of objects with { key : value }
        # fixSegue will take each song and replace previous song with it's segue and sup
        # TODO: Come up with a cleaner and more robust solution in the future
        # TODO: Check for encore
        for x of setlistObj
          if setlistObj.hasOwnProperty x
            setlist.push
              key : x,
              value : setlistObj[x]
        show.net.setlistObj = setlistObj
        show.net.setlist = setlist

        s.set show

  @report = (e, el, next) ->
    $a = $(el).siblings('a.video-link')
    return unless $a.length
    video = model.at $a[0]

    $(el).hide()

    $(el).siblings('.report-actions').slideDown()

  @hideReport = (e, el, next) ->
    $el = $(el)
    $r = $el.siblings('.report-actions:visible')
    return next() unless $r.length
    $r.slideUp()

    return false

  @incorrect = (e, el, next) ->
    $report = $(el).closest('.report-actions')
    return unless $report.length
    # anchor tag
    video = model.at $report.siblings('a.video-link')[0]
    params =
      id: video.get 'id'

    putInfo 'incorrect', params, (json) ->
      video.set 'update', 'Thanks!'
      setTimeout ->
        $report.siblings('.report').fadeIn()
        $report.slideUp -> $report.closest('li').slideUp 'slow', ->
          video.del('update')
      , 800
  @audioOnly = (e, el, next) ->
    $report = $(el).closest('.report-actions')
    return unless $report.length
    # anchor tag
    video = model.at $report.siblings('a.video-link')[0]

    params =
      id: video.get 'id'

    putInfo 'audioOnly', params, (json) ->
      video.set 'update', 'Thanks!'
      setTimeout ->
        $report.siblings('.report').fadeIn()
        $report.slideUp ->
          $report.parent().slideUp()
          video.del('update')
      , 800
  @updateInfo = (e, el, next) ->
    $report = $(el).closest('.report-actions')
    $link = $report.siblings('a.video-link')
    return unless $report.length || $link.length
    # anchor tag
    video = model.at $link[0]
    params =
      id: video.get 'id'
      url: video.get 'video'

    putInfo 'updateInfo', params, (json) ->
      $link.parent().remove()
      video.set json
      video.set 'update', 'Thanks!'
      setTimeout ->
        $report.slideUp ->
          video.del('update')
      , 800
  @expand = (e, el, next) ->
    video = model.at el

    unless video.get('view')
      video.set 'view', true
      $(el).siblings('iframe').slideDown()
    else
      $(el).siblings('iframe').slideUp -> video.set 'view', false
    return false
  @addClick = (e, el) ->
    $add = $('.add-form-container')
    if $add.is(':visible')
      $add.slideUp()
        .siblings('a').removeClass 'active'
    else
      $add.slideDown()
        .siblings('a').addClass 'active'

  # Exported functions are exposed as a global in the browser with the same
  # name as the module that includes Derby. They can also be bound to DOM
  # events using the "x-bind" attribute in a template.
  @stop = ->
    _gaq.push(['_trackEvent', 'User', 'Stability', 'Disconnected', 1])
    # Any path name that starts with an underscore is private to the current
    # client. Nothing set under a private path is synced back to the server.
    model.set '_stopped', true

  do @start = ->
    model.set '_stopped', false

  model.set '_showReconnect', true
  @connect = ->
    _gaq.push(['_trackEvent', 'User', 'Stability', 'Reconnected', 1])
    # Hide the reconnect link for a second after clicking it
    model.set '_showReconnect', false
    setTimeout (-> model.set '_showReconnect', true), 1000
    model.socket.socket.connect()

  @reload = -> window.location.reload()

putInfo = (name, params, callback) ->
  $.ajax
    url: '/api/v1/video/' + name
    type: 'PUT'
    data: params
    success: (json) -> callback json
