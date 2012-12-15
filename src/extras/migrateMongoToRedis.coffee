#!/usr/local/bin/coffee

mongoose = require 'mongoose'
Schema = mongoose.Schema

redis = require("redis")
client = redis.createClient()

mongoose.connect process.env.pv_uri_ext

showSchema = new Schema
  month: Number
  day: Number
  venue: String
  showid: Number
  hasVideos: Boolean

yearSchema = new Schema
  year: Number
  shows: [showSchema]

videoSchema = new Schema
  showid: Number


Year = mongoose.model 'Year', yearSchema

Show = mongoose.model 'Show', showSchema

Video = mongoose.model 'videos', videoSchema

years = [2012, 2011, 2010, 2009, 2004, 2003, 2000, 1999, 1998, 1997, 1996, 1995, 1994, 1993, 1992, 1991, 1990, 1989, 1988, 1987]

objToArr = (obj) ->
  arr = []
  for own key, val of JSON.parse(JSON.stringify(obj))
    arr.push("#{ key }", "#{ val }")

  arr

# if you'd like to select database 3, instead of 0 (default), call
# client.select(3, function() { /* ... */ });
client.on "error", (err) ->
  console.log "Error " + err

years.forEach (y) ->
  Year.findOne
    year: y
  , (err, doc) ->
    return unless doc
    console.log y
    i = 0
    total = doc.shows.length
    doc.shows.forEach (s) ->
      epoch = new Date(y, s.month, s.day ).getTime() / 1000
      client.zadd "shows", "#{epoch}", JSON.stringify(s), redis.print