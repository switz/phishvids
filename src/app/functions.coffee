http = require 'http'
derby = require 'derby'
config = require './config'
{ view } = require './index'
{ addZero, removeDuplicates } = require '../lib/utils'
{ jsonToSetlist, fixSegue, getShow, compareTitleToSetlist } = require '../lib/show_utils'

PhishAPI = require '../api/external_apis/phish_net'

functions =
  index: (page, model) =>
    model.setNull '_years', config.YEAR_ARRAY
    model.del m for m in ['_month','_day','_number','_show','_song','_tiph','_year','_shows']
    model.set s, 'Phish Videos' for s in ['_title', '_stTitle']
    page.render 'index'
  tiph: (page, model) =>
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
      model.set '_title', 'Today in Phish History | Phish Videos'
      page.render 'index'
  year: (page, model, params) =>
    model.setNull '_years', config.YEAR_ARRAY
    model.set '_shows',
      message: 'Loading...'
      error: false
      class: ''

    year = +params[0]

    # Clear unmatched columns
    model.del m for m in ['_month','_day','_number','_show','_song','_tiph']

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
      # derby.util and derby.util.isServer
      page.render 'index'
  show: (page, model, params) =>
    show = model.at '_show'

    model.setNull '_years', config.YEAR_ARRAY
    show.set 'setlist',
      error: 'Loading...'
      class: ''

    year = +params[0]
    month = +params[1]
    day = +params[2]

    # Clear unmatched columns,
    model.del s for s in ['_song','_number','_videos','_tiph']

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
        for x of setlistObj
          if setlistObj.hasOwnProperty x
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

        page.render 'index'

  song: (page, model, params) =>
    model.setNull '_years', config.YEAR_ARRAY
    year = +params[0]
    month = +params[1]
    day = +params[2]
    number = +params[3]

    # Clear models
    model.del '_tiph'

    # Set local models
    model.set '_year', year
    model.set '_month', addZero month
    model.set '_day', addZero day
    model.set '_number', addZero number

    song = model.at '_song'

    # Set up mongodb query
    query = model.query('videos').getVideos year, month, day, number

    # Fetch mongodb query
    model.fetch query, (err, videoModel) ->
      if err
        console.error "Query error: #{err}"

      # Get video model from mongodb
      videoModelGet = videoModel.get()

      if videoModelGet?.length > 0
        songname = videoModelGet[0].songname
        song.set 'songname', songname
        songname += ' '
        model.set '_venue', videoModelGet[0].venue
      else
        songname = ''
        song.set 'songname', songname

      # Set local videos model to videos without audio
      song.set 'videos', videoModel.filter({where:{'audioOnly':false}}).get()
      song.set 'audioVideos', videoModel.filter({where:{'audioOnly': true}}).get()

      model.set '_title', "#{songname}#{month}/#{day}/#{year} | Phish Videos"
      model.set '_stTitle', "#{songname}"

      page.render 'index'

module.exports = functions

# ready callback
require './ready'

# import view functions
require './viewFunctions'
