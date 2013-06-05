config = require './config.coffee'
{ onServer, addZero, removeDuplicates } = require '../lib/utils.coffee'
{ jsonToSetlist, fixSegue, getShow, compareTitleToSetlist } = require '../lib/show_utils.coffee'

PhishAPI = require '../api/external_apis/phish_net.coffee'
approved = true

functions = {}

functions.index = (page, model, params, callback) ->
  # We're on the front page!
  model.set '_info.isFront', true

  model.setNull '_info.years', config.YEAR_ARRAY
  # Clear models
  model.del m for m in ['_info.month','_info.day','_info.number','_info.show','_info.song','_info.tiph','_info.year','_info.shows','_info.about','_info.validateVideos', '_info.scroll.yearList']
  # Set page title and swiftype title
  model.set s, 'Phish Videos' for s in ['_info.title', '_info.stTitle']

  if typeof callback is 'function'
    callback()
  else
    page.render 'index'

functions.tiph = (page, model) ->
  model.set '_info.isFront', false

  model.del m for m in config.DEL_ARRAY.concat ['_info.about']

  _tiph = model.at '_info.tiph'
  today = new Date()
  query = model.query('videos', { month: today.getMonth() + 1, day: today.getDate() })
  # Fetch today in phish history videos
  query.fetch (err) ->
    tiphModel = query.ref '_tiph.data'
    t = tiphModel.get()
    if t?.length
      _tiph.set removeDuplicates t
    else
      today = new Date()
      _tiph.set
        err: true
        message: "Sorry, there were no videos found on #{today.getMonth()+1}/#{today.getDate()}."

    model.set '_info.title', 'Today In Phish History | Phish Videos'
    model.set '_info.stTitle', 'Today In Phish History'

    page.render 'tiph'

functions.about = (page, model) ->
  model.set '_info.isFront', false

  model.set '_info.about', true
  model.del m for m in config.DEL_ARRAY.concat ['_info.tiph']

  model.set '_info.title', 'About | Phish Videos'
  model.set '_info.stTitle', 'About'

  page.render 'about'

functions.year = (page, model, params, callback) ->
  year = +params[0]

  # Clear unmatched columns
  model.del m for m in ['_info.month','_info.day','_info.number','_info.show','_info.song', '_info.scroll.year']

  model.set '_info.year', year

  model.set '_info.shows',
    message: 'Loading...'
    error: false
    class: ''

  query = model.query('years', { year })
  query.fetch (err) ->
    console.log err, err.stack if err
    if err then throw new Error "Year query error: #{err}"

    yearModel = query.ref '_year.data'

    yearModelGet = yearModel.get()

    unless yearModelGet and yearModelGet.length
      model.set '_info.shows',
        message: 'Either our database is down, or there are no shows with video for this year. Sorry.'
        error: true
        class: 'error'
    else if yearModelGet[0].shows
      model.set '_info.shows', yearModelGet[0].shows || []

    model.set '_info.title', "#{year} Phish Videos"
    model.set '_info.stTitle', year

    if typeof callback is 'function'
      callback()
    else
      page.render 'index'

functions.show = (page, model, params, callback) ->
  show = model.at '_info.show'

  show.set 'setlist',
    error: 'Loading...'
    class: ''

  year = +params[0]
  month = +params[1]
  day = +params[2]

  # Clear unmatched columns,
  model.del s for s in ['_info.song','_info.number','_info.videos', '_info.scroll.show']

  # Causing fail when loading up sub url first (/2011) then navigating
  model.set '_info.year', year
  model.set '_info.month', addZero month
  model.set '_info.day', addZero day

  query = model.query('setlists', { year, month, day })
  query.fetch (err) ->
    if err then throw new Error "Show Setlist query error: #{err}"

    setlistModel = query.ref '_setlist.data'
    setlistModelGet = setlistModel.get()[0]

    unless setlistModelGet then return page.render 'index'

    showid = setlistModelGet.showid

    model.set '_info.venue', setlistModelGet.venue

    query2 = model.query('videos', { showid, approved })
    query2.fetch (err) ->
      if err then throw new Error "Show Video query error: #{err}"

      videoModel = query2.ref '_setlist.video.data'
      videoModelGet = videoModel.get()
      console.log videoModelGet

      # Set related local models
      if videoModelGet and setlistModelGet
        blue = {}
        for video in videoModelGet
          continue unless video
          blue[addZero video.number] = true

        model.set '_info.blue', blue
        show.set setlistModelGet

      model.set '_info.title', "#{month}/#{day}/#{year} | Phish Videos"
      model.set '_info.stTitle', "#{month}/#{day}/#{year}"

      if typeof callback is 'function'
        callback()
      else
        page.render 'index'

functions.song = (page, model, params) ->
  year = +params[0]
  month = +params[1]
  day = +params[2]
  number = +params[3]

  model.del '_info.scroll.song'

  # Set local models
  model.set '_info.year', year
  model.set '_info.month', addZero month
  model.set '_info.day', addZero day
  model.set '_info.number', addZero number

  query = model.query 'videos', { year, month, day, number, approved }
  # Fetch mongodb query
  query.fetch (err) ->
    if err then throw new Error "Song query error: #{err}"

    videoModel = query.ref '_video.data'
    # Get video model from mongodb
    videoModelGet = videoModel.get()
    console.log 'videos', videoModelGet

    if videoModelGet?.length > 0
      songname = videoModelGet[0].songname
      model.set '_info.song.songname', songname
      songname += ' '
      # Set local videos model to videos without audio
      model.set '_info.song.videos', audioOnly videoModelGet, false
      model.set '_info.song.audioVideos', audioOnly videoModelGet, true
    else
      songname = ''
      model.set '_info.song.songname', songname

    model.set '_info.title', "#{songname}#{month}/#{day}/#{year} | Phish Videos"
    model.set '_info.stTitle', "#{songname}"

    page.render 'index'

audioOnly = (videos, bool) ->
  videos.filter (el) ->
    audioOnly == bool

module.exports = functions
