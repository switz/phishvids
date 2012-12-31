API_KEY = require('../config').phishnetAPI
API_URL = 'api.phish.net/api.js'

API_FORMAT  = 'json'
API_VERSION = '2.0'

Request = require '../../lib/request'
{ toParam, onClient } = require '../../lib/utils'

phishNetRequestUrl = (params) ->
  "http://#{ API_URL }?#{ toParam(params) }"


clientSideJSONRequest = (requestUrl, callback) ->
  requestUrl += '&callback=?'

  $.getJSON requestUrl, (data) ->
    callback data[0]


# ### PhishAPI.get(showDate, callback)
# `params`: (string) formatted show date
#
# `callback`: (function)
#
get = (showDate, callback) ->
  params =
    method   : 'pnet.shows.setlists.get'
    apikey   : API_KEY
    showdate : showDate
    api      : API_VERSION
    format   : API_FORMAT

  requestUrl = phishNetRequestUrl(params)

  if onClient()
    clientSideJSONRequest(requestUrl, callback)
  else
    request = new Request(requestUrl)
    request.done (response) ->
      callback JSON.parse(response)[0]

    request.fire()

getYear = (year, callback) ->


module.exports = { get }
