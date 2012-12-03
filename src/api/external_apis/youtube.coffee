API_URL = 'gdata.youtube.com/feeds/api/videos'

API_FORMAT  = 'json'
API_VERSION = '2'

Request = require '../../lib/request'
{ toParam } = require '../../lib/utils'

youtubeRequestUrl = (id) ->
  params =
    v   : API_VERSION
    alt : API_FORMAT
    key : 'AI39si5bIHypsjH4oRpew0JP4DObpnfJY_N3BsGevJA3oQcD9_Dv06sCpk-tFmh5khj-oyZP_y6WTsfO-XEtBLPEZR_ZbxwjXg'

  "http://#{ API_URL }/#{ id }?#{ toParam(params) }"


# ### YoutubeAPI.get(id, callback)
# `id` (string) the ID of the youtube video
#
# `callback` (function)
#
get = (id, callback) ->
  request = new Request(youtubeRequestUrl(id))
  request.done (response) ->
    callback JSON.parse(response)

  request.fire()


module.exports = { get }
