{ view } = require './index'
{ addZero } = require '../lib/utils'

# View Functions
view.fn 'addZero', addZero

view.fn 'secsToTime', (secs) ->
  minutes = Math.floor(secs / 60)
  seconds = secs - (minutes * 60)
  minutes + ":" + addZero(seconds)

view.fn 'numberWithCommas', (str) ->
  if str then str.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

view.fn 'parseYouTubeURL', (url) ->
  getParm = (url, base) ->
    re = new RegExp("(\\?|&)#{base}\\=([^&]*)(&|$)")
    matches = url.match(re)
    if matches
      matches[2]
    else
      ""
  retVal = {}
  matches = undefined
  if url && url.indexOf("youtube.com/watch") isnt -1
    return getParm(url, "v")

view.fn 'or', (one, two) ->
  return !!(one || two)