API_KEY = require('../config').phishnetAPI
API_URL = 'api.phish.net/api.js'

API_FORMAT  = 'json'
API_VERSION = '2.0'

Request = require '../../lib/request'
{ toParam, onClient } = require '../../lib/utils'

phishNetRequestUrl = (params) ->
  params.apikey = API_KEY
  params.api = API_VERSION
  params.format = API_FORMAT

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
    method: 'pnet.shows.setlists.get'
    showdate: showDate

  requestUrl = phishNetRequestUrl(params)

  if onClient()
    clientSideJSONRequest(requestUrl, callback)
  else
    request = new Request(requestUrl)
    request.done (response) ->
      callback JSON.parse(response)[0]

    request.fire()

getYear = (year, callback) ->
  params =
    method: 'pnet.shows.query'
    year: year

  requestUrl = phishNetRequestUrl(params)
  request = new Request(requestUrl)

  request.done (response) ->
    callback JSON.parse(response)

  request.fire()


module.exports = { get, getYear }
