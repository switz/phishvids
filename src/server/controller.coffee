expressApp = require('./index.coffee').expressApp
mongoose = require 'mongoose'
sanitize = require('validator').sanitize
config = require './config.coffee'

YoutubeAPI = require '../api/external_apis/youtube.coffee'
extractDate = require '../lib/extract_date.coffee'

{ isEmptyObject } = require '../lib/utils.coffee'

db = mongoose.createConnection(process.env.pv_uri);

## Schemas ##
videoSchema = new mongoose.Schema
  video: String
  month: Number
  day: Number
  year: Number
  venue: String
  name: String
  songname: String
  number: Number
  ip: String
  time:
    type: Date
    default: Date.now
  showid: Number
  thumb: String
  seconds: Number
  viewcount: Number
  user: String
  approved: Boolean
  checked: Boolean
  del: Boolean
  audioOnly: Boolean

## Schemas ##
tweetSchema = new mongoose.Schema
  tweet: String
  showid: Number
  official: Boolean
  url: String
  month: Number
  day: Number
  year: Number
  number: Number
  ready: Boolean

Video = db.model 'videos', videoSchema
Tweet = db.model 'tweets', tweetSchema

parseYouTubeURL = (url) ->
  getParm = (url, base) ->
    re = new RegExp("(\\?|&)" + base + "\\=([^&]*)(&|$)")
    matches = url.match(re)
    if matches
      matches[2]
    else
      ""
  retVal = {}
  matches = undefined
  unless url.indexOf("youtube.com/watch") is -1
    retVal.provider = "youtube"
    retVal.id = getParm(url, "v")
  else if matches = url.match(/vimeo.com\/(\d+)/)
    retVal.provider = "vimeo"
    retVal.id = matches[1]
  retVal

## SERVER ONLY ROUTES ##
controller = {}

controller.api =
  v1:
    video:
      youtube:
        POST: (req, res) ->
          err = config.error.addVideo
          return res.send {err: err} unless req.body.data
          data = sanitize(req.body.data).xss()
          if !data and !data.length then return res.send {err: err}
          videos = []
          i = 0
          len = data.length
          console.log data, typeof data, data.length, [data], new Array data
          data.map (d) =>
            id = parseYouTubeURL(d).id
            unless id then return res.send {err: err}
            YoutubeAPI.get id, (json) =>
              unless json then return res.send {err: err}
              title = sanitize(json.entry.title.$t).xss()
              videos[i++] =
                id: sanitize(json.entry.media$group.yt$videoid.$t).xss()
                showDate: extractDate(title) || extractDate(sanitize(json.entry.media$group.media$description.$t).xss())
                title: title
                author: sanitize(json.entry.author[0].name.$t).xss()
                thumb: sanitize(json.entry.media$group.media$thumbnail[0].url).xss()
                #desc: sanitize(json.entry.media$group.media$description.$t).xss()
                json: json
              if i is len
                res.json videos
      add:
        POST: (req, res) ->
          data = sanitize(req.body.show).xss()
          month = sanitize(data.showDate.month).toInt()
          day = sanitize(data.showDate.day).toInt()
          year = sanitize(data.showDate.year).toInt()
          showid = sanitize(data.net.showid).toInt()
          approved = false

          adminKey = sanitize(req.body.adminKey || '').xss() || ''

          if adminKey is process.env.admin_key
            approved = true

          for number of data.songnames
            songname = sanitize(data.songnames[number]).xss()
            v =
              video: "http://www.youtube.com/watch?v=#{sanitize(data.id).xss()}"
              month: month
              day: day
              year: year
              venue: sanitize(data.net.venue).xss()
              name: sanitize(data.title).xss()
              songname: songname
              number: +number
              ip: req.ip
              time: new Date()
              #thumb:
              showid: showid
              seconds: sanitize(data.json.entry.media$group.yt$duration.seconds).toInt()
              viewcount: sanitize(data.json.entry.yt$statistics.viewCount).toInt()
              user: sanitize(data.author).xss()
              approved: approved
              checked: approved
              del: false
              audioOnly: false

            new Video(v).save()

            t =
              tweet: "New Phish Video | #{month}/#{day}/#{year} | #{songname} http://PhishVids.com/#{month}/#{day}/#{year}/#{number}"
              showid: showid
              official: false
              url: "http://PhishVids.com/#{year}/#{month}/#{day}/#{number}"
              month: month
              day: day
              year: year
              number: number
              ready: approved #if admin

            new Tweet(t).save()
          res.json data
      incorrect:
        PUT: (req, res) ->
          v = Video.findById sanitize(req.body.id).xss(), (err, video) ->
            if (err) then console.log err
            video.del = true
            video.save (err) ->
              if err then console.log 'save err:', err
              res.json video
      audioOnly:
        PUT: (req, res) ->
          v = Video.findById sanitize(req.body.id).xss(), (err, video) ->
            if (err) then console.log err
            video.audioOnly = (!video.audioOnly)
            video.save (err) ->
              if err then console.log 'save err:', err
              res.json video
      updateInfo:
        PUT: (req, res) ->
          youtubeID = parseYouTubeURL(sanitize(req.body.url || '').xss()).id
          YoutubeAPI.get youtubeID, (json) ->
            return res.send {err: true} unless json
            video =
              name: sanitize(json.entry.title.$t).xss()
              user: sanitize(json.entry.author[0].name.$t).xss()
              thumb: sanitize(json.entry.media$group.media$thumbnail[0].url).xss()
              seconds: sanitize(json.entry.media$group.yt$duration.seconds).toInt()
              viewcount: sanitize(json.entry.yt$statistics.viewCount).toInt()
            Video.findByIdAndUpdate sanitize(req.body.id).xss(), video, {new: true}, (err, doc) ->
              if (err) then console.log 'yt', err
              res.json doc

controller.status = (req, res) ->
  obj =
    status: 'up'
    easteregg: false
    version: 'Running on Derby 0.5.x'
  if req.query.easteregg
    obj.easteregg = true
    obj.icculus = 'Read the fucking book.'
  res.json obj

controller.all = (req, res) ->
  throw "404: #{req.url}"

module.exports = controller
