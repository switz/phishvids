{ get } = require './index'
controller = require './controller'

## ROUTES ##

get '/', controller.index
get '/tiph', controller.tiph
get '/about', controller.about
get /^\/([0-9]{4})\/?$/, controller.year
get /^\/([0-9]{4})\/([0-9]{1,2})\/([0-9]{1,2})\/?$/, controller.show
get /^\/([0-9]{4})\/([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{1,2})\/?$/, controller.song
