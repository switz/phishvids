config = require './config'
{ onServer, addZero, removeDuplicates } = require '../lib/utils'
{ jsonToSetlist, fixSegue, getShow, compareTitleToSetlist } = require '../lib/show_utils'

PhishAPI = require '../api/external_apis/phish_net'

functions = {}

functions.index = (page, model, params, callback) ->
  # We're on the front page!
  model.set '_isFront', true

  model.setNull '_years', config.YEAR_ARRAY
  # Clear models
  model.del m for m in ['_month','_day','_number','_show','_song','_tiph','_year','_shows','_about','_validateVideos', '_scroll.yearList']
  # Set page title and swiftype title
  model.set s, 'Phish Videos' for s in ['_title', '_stTitle']

  if typeof callback is 'function'
    callback()
  else
    page.render 'index'

functions.tiph = (page, model) ->
  model.set '_isFront', false

  model.del m for m in config.DEL_ARRAY.concat ['_about']

  _tiph = model.at '_tiph'
  # Fetch today in phish history videos
  model.fetch model.query('videos').tiph(), (err, tiphModel) ->
    t = tiphModel.get()
    if t?.length
      _tiph.set removeDuplicates t
    else
      today = new Date()
      _tiph.set
        err: true
        message: "Sorry, there were no videos found on #{today.getMonth()+1}/#{today.getDate()}."

    model.set '_title', 'Today In Phish History | Phish Videos'
    model.set '_stTitle', 'Today In Phish History'

    page.render 'tiph'

functions.about = (page, model) ->
  model.set '_isFront', false

  model.set '_about', true
  model.del m for m in config.DEL_ARRAY.concat ['_tiph']

  model.set '_title', 'About | Phish Videos'
  model.set '_stTitle', 'About'

  page.render 'about'

functions.year = (page, model, params, callback) ->
  year = +params[0]

  # Clear unmatched columns
  model.del m for m in ['_month','_day','_number','_show','_song', '_scroll.year']

  model.set '_year', year

  model.set '_shows',
    message: 'Loading...'
    error: false
    class: ''

  model.fetch model.query('years').getYearsShows(year), (err, yearModel) ->
    #if err then throw new Error "Year query error: #{err}"
    console.log err if err and console

    yearModelGet = yearModel.get()

    unless yearModelGet and yearModelGet.length
      model.set '_shows',
        message: 'Either our database is down, or there are no shows with video for this year. Sorry.'
        error: true
        class: 'error'
    else if yearModelGet[0].shows
      model.set '_shows', yearModelGet[0].shows || []

    model.set '_title', "#{year} Phish Videos"
    model.set '_stTitle', year

    if typeof callback is 'function'
      callback()
    else
      page.render 'index'

functions.show = (page, model, params, callback) ->
  show = model.at '_show'

  show.set 'setlist',
    error: 'Loading...'
    class: ''

  year = +params[0]
  month = +params[1]
  day = +params[2]

  # Clear unmatched columns,
  model.del s for s in ['_song','_number','_videos', '_scroll.show']

  # Causing fail when loading up sub url first (/2011) then navigating
  model.set '_year', year
  model.set '_month', addZero month
  model.set '_day', addZero day

  model.fetch model.query('setlists').getSetlist(year, month, day), (err, setlistModel) ->
    if err then throw new Error "Show Setlist query error: #{err}"

    setlistModelGet = setlistModel.get()[0]

    unless setlistModelGet then return page.render 'index'

    showid = setlistModelGet.showid

    model.set '_venue', setlistModelGet.venue

    model.fetch model.query('videos').checkIfVideosExistForSetlist(showid), (err, videoModel) ->
      if err then throw new Error "Show Video query error: #{err}"

      videoModelGet = videoModel.get()

      # Set related local models
      if videoModelGet and setlistModelGet
        blue = {}
        for video in videoModelGet
          blue[addZero video.number] = true

        model.set '_blue', blue
        show.set setlistModelGet

      model.set '_title', "#{month}/#{day}/#{year} | Phish Videos"
      model.set '_stTitle', "#{month}/#{day}/#{year}"

      if typeof callback is 'function'
        callback()
      else
        page.render 'index'

functions.song = (page, model, params) ->
  year = +params[0]
  month = +params[1]
  day = +params[2]
  number = +params[3]

  model.del '_scroll.song'

  # Set local models
  model.set '_year', year
  model.set '_month', addZero month
  model.set '_day', addZero day
  model.set '_number', addZero number

  # Fetch mongodb query
  model.fetch model.query('videos').getVideos(year, month, day, number), (err, videoModel) ->
    if err then throw new Error "Song query error: #{err}"

    # Get video model from mongodb
    videoModelGet = videoModel.get()

    if videoModelGet?.length > 0
      songname = videoModelGet[0].songname
      model.set '_song.songname', songname
      songname += ' '
      # Set local videos model to videos without audio
      model.set '_song.videos', videoModel.filter({where:{'audioOnly':false}}).get()
      model.set '_song.audioVideos', videoModel.filter({where:{'audioOnly': true}}).get()
    else
      songname = ''
      model.set '_song.songname', songname

    model.set '_title', "#{songname}#{month}/#{day}/#{year} | Phish Videos"
    model.set '_stTitle', "#{songname}"

    page.render 'index'

module.exports = functions
