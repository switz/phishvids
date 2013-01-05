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

setSchema = new Schema
  number: String
  songs: [songSchema]

setlistSchema = new Schema
  year: Number
  month: Number
  day: Number
  venue: String
  showid: Number
  notes: String
  footnotes: String
  city: String
  state: String
  country: String
  setlist: [setSchema]

showSchema = new Schema
  month: Number
  day: Number
  venue: String
  showid: Number
  hasVideos: Boolean

yearSchema = new Schema
  year: Number
  shows: [showSchema]

Year = mongoose.model 'Year', yearSchema
Setlist = mongoose.model 'Setlist', setlistSchema

## FUNCTIONS ##

showDateToDate = (showDate) ->
  # showDate is in the format of 2012-12-31
  [year, month, day] = showDate.split('-')
  return {year, month, day}

cleanShow = (item, callback) ->
  date = showDateToDate item.showdate
  show =
    month: +date.month
    day: +date.day
    venue: item.venue
    showid: +item.showid
    hasVideos: false
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
      json.footnotes = $('.pnetfootnotes').html()
      $('.pnetset').each ->
        $this = $(@)
        number = $this.children('.pnetsetlabel').text().replace(/(?:\:|Set ([0-9]):)/, '$1')
        set =
          number: number
          songs: []
        window.last = $this.children('a').last()[0]
        $this.children('a').each ->
          sup = ''
          if $(this).next().is('sup')
            sup = $(this).next().text().replace(/\[([0-9]{1,2})\]/, '$1')
            segue = $(this.nextSibling.nextSibling).text()
          else
            segue = $(this.nextSibling).text()
          switch segue
            when ' -' then segue = '->'
            when ' ' then segue = '>'
            else segue = ','
          if window.last.isEqualNode $(this)[0]
            segue = ''
          song =
            name: $(this).text()
            sup: sup
            segue: segue
          set.songs.push song
        setlist.push set
      callback setlist, json

cleanShowForSetlist = (item, callback) ->
  date = showDateToDate item.showdate
  getSetlist item, (setlist, json) ->
    show =
      year: +date.year
      month: +date.month
      day: +date.day
      venue: item.venue
      showid: +item.showid
      footnotes: json.footnotes
      notes: json.setlistnotes
      city: json.city
      state: json.state
      country: json.country
      setlist: setlist
    new Setlist(show).save()
    callback()


getSetlists = (year = 2012) ->
  PhishAPI.getYear year, (json) ->
    async.forEach json, cleanShowForSetlist, (err) ->
      console.log "Adding #{json.length} setlists for #{year}"
      setTimeout ->
        process.exit(0)
      , 1000


## CLI ##

program
  .version('0.1')

program
  .command('year [year]')
  .description('\nUpdate the year list for a particular year. If no year is provided, 2012 will be default.')
  .action(getShows)

program
  .command('setlists [year]')
  .description('\nUpdate the setlists for a particular year. If no year is provided, 2012 will be default.')
  .action(getSetlists)

program.parse process.argv
