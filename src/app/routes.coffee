{ get } = require './index'
functions = require './functions'

## ROUTES ##

get '/', functions.index
get '/tiph', functions.tiph
get /^\/([0-9]{4})\/?$/, functions.year
get /^\/([0-9]{4})\/([0-9]{1,2})\/([0-9]{1,2})\/?$/, functions.show
get /^\/([0-9]{4})\/([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{1,2})\/?$/, functions.song