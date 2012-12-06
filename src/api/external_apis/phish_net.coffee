API_KEY = require('../config').phishnetAPI
API_URL = 'api.phish.net/api.js'
METHOD  = 'pnet.shows.setlists.get'

API_FORMAT  = 'json'
API_VERSION = '2.0'

Request = require '../../lib/request'
{ toParam, onClient } = require '../../lib/utils'

phishNetRequestUrl = (showDate) ->
  params =
    method   : METHOD
    apikey   : API_KEY
    showdate : showDate
    api      : API_VERSION
    format   : API_FORMAT

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
  requestUrl = phishNetRequestUrl(showDate)

  if onClient()
    clientSideJSONRequest(requestUrl, callback)
  else
    request = new Request(requestUrl)
    request.done (response) ->
      callback JSON.parse(response)[0]

    request.fire()


module.exports = { get }
