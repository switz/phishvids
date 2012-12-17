config = require './config'
{ onServer, addZero, removeDuplicates } = require '../lib/utils'
{ jsonToSetlist, fixSegue, getShow, compareTitleToSetlist } = require '../lib/show_utils'

PhishAPI = require '../api/external_apis/phish_net'

functions = {}

functions.index = (page, model, params, callback) ->
  model.set '_isFront', true

  model.setNull '_years', config.YEAR_ARRAY
  model.del m for m in ['_month','_day','_number','_show','_song','_tiph','_year','_shows','_about','_validateVideos']
  model.set s, 'Phish Videos' for s in ['_title', '_stTitle']

  if typeof callback is 'function'
    callback()
  else
    page.render 'index'

functions.tiph = (page, model) ->
  model.set '_isFront', false

  _tiph = model.at '_tiph'
  model.fetch model.query('videos').tiph(), (err, tiphModel) ->
    t = tiphModel.get()
    if t?.length
      _tiph.set removeDuplicates t
    else
      today = new Date()
      _tiph.set
        err: true
        message: "Sorry, there were no videos found on #{today.getMonth()+1}/#{today.getDate()}."

    model.del m for m in config.DEL_ARRAY.concat ['_about']

    model.set '_title', 'Today In Phish History | Phish Videos'
    model.set '_stTitle', 'Today In Phish History'

    page.render 'index'

functions.about = (page, model) ->
  model.set '_isFront', false

  model.set '_about', true
  model.del m for m in config.DEL_ARRAY.concat ['_tiph']

  model.set '_title', 'About | Phish Videos'
  model.set '_stTitle', 'About'

  page.render()

functions.year = (page, model, params, callback) ->
  model.set '_isFront', true

  model.set '_shows',
    message: 'Loading...'
    error: false
    class: ''

  year = +params[0]

  # Clear unmatched columns
  model.del m for m in ['_month','_day','_number','_show','_song']

  model.set '_year', year

  model.fetch model.query('years').getYearsShows(year), (err, yearModel) ->
    if err
      console.error "Query Error: #{err}"

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
  model.set '_isFront', true

  show = model.at '_show'

  show.set 'setlist',
    error: 'Loading...'
    class: ''

  year = +params[0]
  month = +params[1]
  day = +params[2]

  # Clear unmatched columns,
  model.del s for s in ['_song','_number','_videos']

  # Causing fail when loading up sub url first (/2011) then navigating
  model.set '_year', year
  model.set '_month', addZero month
  model.set '_day', addZero day

  # Run query against the Phish.net API
  showDate = "#{year}-#{addZero month}-#{addZero day}"
  PhishAPI.get showDate, (json) ->
    unless json || json.setlistdata
      show.set 'setlist'
        error: config.error.phishnet
        class: 'error'
      return -1

    showid = parseInt json.showid, 10
    show.set 'showid', showid

    # Grab footnotes
    footnotes = json.setlistdata.split(/<p class='pnetfootnotes'>/)?[1]

    blue = {}

    model.fetch model.query('videos').checkIfVideosExistForSetlist(showid), (err, videoModel) ->
      if err
        console.error "Query error: #{err}"

      videoModelGet = videoModel.get()

      if videoModelGet
        for video in videoModelGet
          blue[video.number] = 'blue'

      setlist = []
      # fixSegue will take each song and replace previous song with it's segue and sup
      setlistObj = fixSegue jsonToSetlist(json, blue)

      # Just a crappy hack to satisfy Derby templating
      # Converts object to array of objects with { key : value }
      # TODO: Come up with a cleaner and more robust solution in the future
      # TODO: Check for encore
      for own x of setlistObj
        setlist.push
          key : x,
          value : setlistObj[x]

      # Set related local models
      if setlist
        show.set 'setlist', setlist
        show.set 'footnotes', footnotes
        show.set 'venue', json.venue
        model.set '_venue', json.venue
      else
        show.set 'setlist',
          error: 'Phish.net API could not be reached. Please try again later.'
          class: 'error'

      model.set '_title', "#{month}/#{day}/#{year} | Phish Videos"
      model.set '_stTitle', "#{month}/#{day}/#{year}"

      if typeof callback is 'function'
        callback()
      else
        page.render 'index'

functions.song = (page, model, params) ->
  model.set '_isFront', true

  model.set '_song',
    error: 'Loading...'
    class: ''

  year = +params[0]
  month = +params[1]
  day = +params[2]
  number = +params[3]

  # Set local models
  model.set '_year', year
  model.set '_month', addZero month
  model.set '_day', addZero day
  model.set '_number', addZero number
  model.set '_isServer', onServer()
  console.log onServer()

  # Fetch mongodb query
  model.fetch model.query('videos').getVideos(year, month, day, number), (err, videoModel) ->
    if err
      console.error "Query error: #{err}"

    # Get video model from mongodb
    videoModelGet = videoModel.get()

    if videoModelGet?.length > 0
      songname = videoModelGet[0].songname
      model.set '_song',
        songname: songname
        videos: videoModel.filter({where:{'audioOnly':false}}).sort(['viewcount', 'desc']).get()
        audioVideos: videoModel.filter({where:{'audioOnly': true}}).sort(['viewcount', 'desc']).get()
      songname += ' '
    else
      songname = ''
      model.set '_song.songname', songname

    model.set '_title', "#{songname}#{month}/#{day}/#{year} | Phish Videos"
    model.set '_stTitle', "#{songname}"

    page.render 'song'

module.exports = functions
