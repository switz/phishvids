#!/usr/local/bin/coffee

mongoose = require 'mongoose'
Schema = mongoose.Schema

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

years.forEach (y) ->
	Year.findOne
		year: y
	, (err, doc) ->
		return unless doc
		console.log y
		i = 0
		total = doc.shows.length
		doc.shows.forEach (s) ->
			i++
			Video.findOne
				showid: s.showid
			, (err2, video) ->
				if video
					s.hasVideos = true
				else
					s.hasVideos = false
				if i is total
					doc.save()
