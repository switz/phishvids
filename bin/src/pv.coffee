program = require 'derby/node_modules/commander'
async = require 'async'
PhishAPI = require '../../src/api/external_apis/phish_net'

mongoose = require 'mongoose'
Schema = mongoose.Schema

mongoose.connect process.env.pv_uri_ext
console.log process.env.pv_uri_ext

## SCHEMA ##

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

## FUNCTIONS ##

showDateToDate = (showDate) ->
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



## CLI ##

program
  .version('0.1')

program
  .command('year [year]')
  .description('''
    \nCreate a new Derby project. If no directory name is specified, or the
    name `.` is used, the project will be created in the current directory.
    A name for the default app may be specified optionally.''')
  .action(getShows)

program.parse process.argv
