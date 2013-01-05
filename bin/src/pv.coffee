program = require 'derby/node_modules/commander'
async = require 'async'
jsdom = require 'jsdom'
PhishAPI = require '../../src/api/external_apis/phish_net'

mongoose = require 'mongoose'
Schema = mongoose.Schema

mongoose.connect process.env.pv_uri_ext

## SCHEMA ##

songSchema = new Schema
  name: String
  segue: String
  sup: String

setlistSchema = new Schema
  number: String
  songs: [songSchema]

showSchema = new Schema
  month: Number
  day: Number
  venue: String
  showid: Number
  hasVideos: Boolean
  setlist: [setlistSchema]

yearSchema = new Schema
  year: Number
  shows: [showSchema]

Year = mongoose.model 'Year', yearSchema

## FUNCTIONS ##

showDateToDate = (showDate) ->
  # showDate is in the format of 2012-12-31
  [year, month, day] = showDate.split('-')
  return {year, month, day}

cleanShow = (item, callback) ->
  date = showDateToDate item.showdate
  getSetlist item, (setlist) ->
    show =
      month: +date.month
      day: +date.day
      venue: item.venue
      showid: +item.showid
      hasVideos: false
      setlist: setlist
    callback null, show

getShows = (year = 2012) ->
  PhishAPI.getYear year, (json) ->
    async.map json, cleanShow, (err, shows) ->
      y =
        year: year
        shows: shows
      console.log "Adding #{shows.length} shows for #{year}"
      new Year(y).save()
      setTimeout ->
        process.exit(0)
      , 1000

getSetlist = (show, callback) ->
  PhishAPI.get show.showdate, (json) ->
    jsdom.env json.setlistdata, ["http://code.jquery.com/jquery.js"], (err, window) ->
      $ = window.$
      setlist = []
      $('.pnetset').each ->
        $this = $(@)
        number = $this.children('.pnetsetlabel').text().replace(/(?:\:|Set ([0-9]):)/, '$1')
        set =
          number: number
          songs: []
        $this.children('a').each ->
          sup = ''
          if $(this).next().is('sup')
            sup = $(this).next().text().replace(/\[([0-9]{1,2})\]/, '$1')
            segue = $(this.nextSibling.nextSibling).text()
          else
            segue = $(this.nextSibling).text()
          switch segue
            when '-' then segue = '->'
            when ' ' then segue = '>'
            else segue = ','
          song =
            name: $(this).text()
            sup: sup
            segue: segue
          set.songs.push song
        setlist.push set
      callback setlist


## CLI ##

program
  .version('0.1')

program
  .command('year [year]')
  .description('\nUpdate the year list for a particular year. If no year is provided, 2012 will be default.')
  .action(getShows)

program.parse process.argv
